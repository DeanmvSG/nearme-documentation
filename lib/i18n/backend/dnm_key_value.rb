class I18n::Backend::DNMKeyValue < I18n::Backend::KeyValue

  attr_accessor :instance_id

  def initialize(cache, subtrees=true)
    @cache, @subtrees = cache, subtrees
    rebuild!
  end

  def rebuild!
    @store, @timestamps = {}, {}
    prepare_store
  end

  def prepare_store
    Translation.uniq.pluck(:instance_id).each do |instance_id|
      _instance_key = instance_key(instance_id)
      populate(instance_id)
    end
  end

  def set_instance_id(instance_id)
    self.instance_id = instance_id
  end

  def update_cache(_instance_id)
    populate(_instance_id)
    populate(nil)
  end

  def populate(_instance_id)
    _instance_key = instance_key(_instance_id)
    @store[_instance_key] ||= {}
    translations_scope = (_instance_id.nil? ? Translation.defaults : Translation.for_instance(_instance_id))
    translations_scope = translations_scope.where('updated_at > ?', @timestamps[_instance_id]) if @timestamps[_instance_id].present?
    translations_scope.pluck(:locale, :key, :value, :instance_id).each do |translation|
      store_translation(translation)
    end
    @timestamps[_instance_id] = Time.zone.now
  end

  def store_translation(translation)
    store_translations(translation[0], convert_dot_to_hash(translation[1], translation[2]), {:instance_id => translation[3]})
  end

  def store_translations(locale, data, options = {})
    escape = options.fetch(:escape, true)
    _instance_key = instance_key(options[:instance_id])
    flatten_translations(locale, data, escape, @subtrees).each do |key, value|
      key = "#{locale}.#{key}"
      case value
      when Hash
        if @subtrees && (old_value = @store[_instance_key][key])
          old_value = ActiveSupport::JSON.decode(old_value)
          value = old_value.deep_symbolize_keys.deep_merge!(value) if old_value.is_a?(Hash)
        end
      when Proc
        raise "Key-value stores cannot handle procs"
      end
      @store[_instance_key][key] = ActiveSupport::JSON.encode(value) unless value.is_a?(Symbol)
    end
  end

  def available_locales
    locales = @store[instance_key(nil)].keys.map { |k| k =~ /\./; $` }
    locales.uniq!
    locales.compact!
    locales.map! { |k| k.to_sym }
    locales
  rescue
    []
  end

  protected

  def lookup(locale, key, scope = [], options = {})
    key = normalize_flat_keys(locale, key, scope, options[:separator])

    value = lookup_for_instance_key locale, key
    value = lookup_for_default_key locale, key if value.blank?

    # Fallback to English
    if value.blank? && locale != :en
      value = lookup_for_en_instance_key(key)
      value = lookup_for_en_default_key(key) if value.blank?
    end

    value.is_a?(Hash) ? value.deep_symbolize_keys : value
  end

  def lookup_for_instance_key(locale, key)
    value = @store[instance_key(instance_id)]["#{locale}.#{key}"]
    sanitize_empty_value value
  rescue
    nil
  end

  def lookup_for_default_key(locale, key)
    value = @store[instance_key(nil)]["#{locale}.#{key}"]
    sanitize_empty_value value
  rescue
    nil
  end

  def lookup_for_en_instance_key(key)
    lookup_for_instance_key(:en, key)
  end

  def lookup_for_en_default_key(key)
    lookup_for_default_key(:en, key)
  end

  # Note that we have to JSON.decode first, as 'empty' value is "\"\"" before that and blank? would return false instead of true
  def sanitize_empty_value(value)
    value.present? ? ActiveSupport::JSON.decode(value) : value
  end

  # transforms key in format "a.b.c.d" and value "x" to hash
  # { :a => { :b => { :c => { :d => "x" } } } }
  def convert_dot_to_hash(string, value = nil, hash = {})
    arr = string.split(".")
    if arr.size == 1
      hash[arr.shift] = value
    else
      el = arr.shift
      hash[el] ||= {}
      hash[el] = convert_dot_to_hash(arr.join('.'), value, hash[el])
    end
    hash
  end

  def instance_key(instance_id)
    instance_id.present? ? "#{instance_id}".to_sym : :default
  end

end

