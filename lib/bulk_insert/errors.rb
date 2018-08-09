module BulkInsert
  class OptionsNotAvailable < ArgumentError
    def initialize(msg: nil, **args)
      @msg = msg || "The option provided (#{args[:option]}) "\
                    "is not available for adapter: #{args[:adapter]}"
      super(@msg)
    end
  end
end
