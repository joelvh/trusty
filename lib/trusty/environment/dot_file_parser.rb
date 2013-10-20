require 'dotenv'

module Trusty
  module Environment
    class DotFileParser < Dotenv::Environment
      
      def initialize(source)
        @source = source
      end
      
      def read
        @source.split("\n")
      end
      
      alias_method :parse, :load
      
    end
  end
end