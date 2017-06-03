module Trusty
  module Sorting
    module Atoms
      class Version < Array
        def initialize(version_string, *minor_and_patch)
          case version_string
          when Integer
            super [version_string] + minor_and_patch
          when Array
            super
          when String
            super version_string.split('.').map(&:to_i)
          else
            raise "Invalid version specified"
          end
        end
      end
    end
  end
end
