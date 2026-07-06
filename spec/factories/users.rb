FactoryBot.define do
  factory :user do
    name {'user'}
    email_address { "user@example.com" }
    password { "password" }
    password_confirmation { "password" }

    trait :incorrect_password do
      password {"password"}
      password_confirmation {"123"}
    end

    trait :bob do
      name {'Bob'}
      email_address {"bob@example.com"}
    end

    trait :jeff do
      name {'Jeff'}
      email_address {"jeff@example.com"}
    end

    trait :henry do
      name {'Henry'}
      email_address {"henry@example.com"}
    end

    trait :batman do
      name {'Batman'}
      email_address {"notwayne@example.com"}
    end

    factory :user_incorrect_password, traits: [:incorrect_password]

    factory :user1, traits: [:bob]
    factory :user2, traits: [:jeff]
    factory :user3, traits: [:henry]
    factory :user4, traits: [:batman]
  end
end
