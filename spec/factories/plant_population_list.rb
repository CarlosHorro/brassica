FactoryGirl.define do
  factory :plant_population_list do
    sort_order '1'
    user
    annotable_no_owner
  end
end
