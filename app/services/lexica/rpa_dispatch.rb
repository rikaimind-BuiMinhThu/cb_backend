module Lexica
  class RpaDispatch
    def self.action_for(claim)
      case claim["action"].to_s
      when "defer" then :requeue
      when "run" then :run
      else :finish
      end
    end
  end
end
