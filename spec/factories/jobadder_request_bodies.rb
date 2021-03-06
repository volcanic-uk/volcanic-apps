FactoryGirl.define do
  json_body = '{
  "firstName": "string",
  "lastName": "string",
  "email": "string",
  "phone": "string",
  "mobile": "string",
  "salutation": "string",
  "statusId": 0,
  "rating": "string",
  "source": "string",
  "seeking": "Yes",
  "social": {
    "facebook": "https://www.facebook.com/JobAdder",
    "twitter": "https://twitter.com/jobadder",
    "linkedin": "https://www.linkedin.com/company/866656/",
    "googleplus": "https://plus.google.com/+Jobadder",
    "youtube": "https://www.youtube.com/c/jobadder",
    "other": "https://jobadder.com/company/"
  },
  "address": {
    "street": [
      "string"
    ],
    "city": "string",
    "state": "string",
    "postalCode": "string",
    "countryCode": "string"
  },
  "skillTags": [
    "string"
  ],
  "employment": {
    "current": {
      "employer": "string",
      "position": "string",
      "workTypeId": 0,
      "salary": {
        "ratePer": "Hour",
        "rate": 0,
        "currency": "string"
      }
    },
    "ideal": {
      "position": "string",
      "workTypeId": 0,
      "salary": {
        "ratePer": "Hour",
        "rateLow": 0,
        "rateHigh": 0,
        "currency": "string"
      },
      "other": [
        {
          "workTypeId": 0,
          "salary": {
            "ratePer": "Hour",
            "rateLow": 0,
            "rateHigh": 0,
            "currency": "string"
          }
        }
      ]
    },
    "history": [
      {
        "employer": "string",
        "position": "string",
        "start": "string",
        "end": "string",
        "description": "string"
      }
    ]
  },
  "availability": {
    "immediate": true,
    "relative": {
      "period": 0,
      "unit": "Week"
    },
    "date": "2018-10-17"
  },
  "education": [
    {
      "institution": "string",
      "course": "string",
      "date": "string"
    }
  ],
  "custom": [
    {
      "fieldId": 1,
      "value": "Text value"
    }
  ],
  "recruiterUserId": [
    0
  ]
}
'
  factory :jobadder_request_body do
    request_type 'POST'
    endpoint '/candidates'
    name 'add_candidate'
    json json_body
  end

end

