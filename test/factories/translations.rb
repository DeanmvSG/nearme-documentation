# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :translation do
    locale 'en'
    key 'translation_key'
    value 'translation-value'
    instance_id { PlatformContext.current.instance.id }

    factory :czech_translation do
      locale 'cs'
    end
  end
end