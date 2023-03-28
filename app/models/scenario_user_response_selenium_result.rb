class ScenarioUserResponseSeleniumResult < ApplicationRecord
  enum result: { open: 0, running: 1, done: 2, error: 3 }
end
