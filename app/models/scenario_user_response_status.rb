class ScenarioUserResponseStatus < ApplicationRecord
  belongs_to :scenario

  enum status: {finished: 1, un_finished: 0}
end