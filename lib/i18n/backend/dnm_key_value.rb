class I18n::Backend::DNMKeyValue < I18n::Backend::KeyValue

  attr_accessor :instance_id

  def initialize(cache, subtrees=true)
    @cache, @subtrees, @store = cache, subtrees, {}
    prepare_store
  end

  def prepare_store
    Translation.uniq.pluck(:instance_id).each do |instance_id|
      generated_cache = false
      _instance_key = instance_key(instance_id)
      @store[_instance_key] = @cache.fetch "locales.#{_instance_key}" do
        generated_cache = true
        populate(instance_id)
        @store[_instance_key]
      end
      cache_updated_at = write_cached_at_for(_instance_key) if generated_cache
      touch_cache_timestamp_for(_instance_key, generated_cache ? cache_updated_at : Time.zone.now) 
    end
  end

  def set_instance_id(instance_id)
    self.instance_id = instance_id
    update_store_if_necessary(instance_id)
    update_store_if_necessary(nil)
    populate(instance_id)
    populate(nil)
  end

  def update_store_if_necessary(_instance_id)
    _instance_key = instance_key(_instance_id)
    cache_updated_at = read_cached_at_for(_instance_key)
    if cache_updated_at && cache_updated_at > get_cache_timestamp_for(_instance_key)
      touch_cache_timestamp_for(_instance_key)
      @store[_instance_key] = @cache.read "locales.#{_instance_key}" 
    end
  end

  def populate(_instance_id)
    cache_changed = false
    _instance_key = instance_key(_instance_id)
    translations_scope = (_instance_key == :default ? Translation.defaults : Translation.for_instance(_instance_id))
    translations_scope = translations_scope.updated_after(get_cache_timestamp_for(_instance_key)) if get_cache_timestamp_for(_instance_key)
    translations_scope.find_each do |translation|
      cache_changed = true
      store_translation(translation)
    end
    if cache_changed && get_cache_timestamp_for(_instance_key)
      @cache.write "locales.#{_instance_key}", @store[_instance_key]
      touch_cache_timestamp_for(_instance_key, write_cached_at_for(_instance_key))
    end
  end

  def store_translation(translation)
    store_translations(translation.locale, convert_dot_to_hash(translation.key, translation.value), { :instance_id => translation.instance_id })
  end

  def store_translations(locale, data, options = {})
    escape = options.fetch(:escape, true)
    _instance_key = instance_key(options[:instance_id])
    @store[_instance_key] ||= {}
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
    locales = @store[self.instance_id.to_sym].keys.map { |k| k =~ /\./; $` }
    locales.uniq!
    locales.compact!
    locales.map! { |k| k.to_sym }
    locales
  end


  protected

  def lookup(locale, key, scope = [], options = {})
    key = normalize_flat_keys(locale, key, scope, options[:separator])
    value = begin @store[instance_key(self.instance_id)]["#{locale}.#{key}"] rescue nil end
    value = ActiveSupport::JSON.decode(value) if value.present?
    # note that we have to JSON.decode first, as 'empty' value is "\"\"" before that and blank? would return false instead of true
    if value.blank?
      value = begin @store[instance_key(nil)]["#{locale}.#{key}"] rescue nil end
      value = ActiveSupport::JSON.decode(value) if value.present?
    end
    value.is_a?(Hash) ? value.deep_symbolize_keys : value
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

  def touch_cache_timestamp_for(_instance_key, time = Time.zone.now)
    @timestamps ||= {}
    @timestamps[_instance_key] = time
  end

  def get_cache_timestamp_for(_instance_key)
    @timestamps && @timestamps[_instance_key]
  end

  def instance_key(instance_id)
    instance_id.present? ? "#{instance_id}".to_sym : :default
  end
  
  def write_cached_at_for(_instance_key)
    Time.zone.now.tap { |time| @cache.write "locales.#{_instance_key}.cached_at", time }
  end

  def read_cached_at_for(_instance_key)
    @cache.read "locales.#{_instance_key}.cached_at"
  end

end
