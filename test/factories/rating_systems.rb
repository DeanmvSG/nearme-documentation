# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :rating_system do
    instance
    subject { [instance.bookable_noun, instance.lessor, instance.lessee].sample }
    active false
  end

  factory :active_rating_system, parent: :rating_system do
    active true
  end
end
