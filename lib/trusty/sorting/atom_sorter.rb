#
# Based on https://makandracards.com/makandra/9185-ruby-natural-sort-strings-with-umlauts-and-other-funny-characters
#
module Trusty
  module Sorting
    class AtomSorter

      attr_reader :value, :index

      def initialize(value, index)
        @value = value
        @index = index
      end

      def <=>(other)
        other.is_a?(self.class) or raise "Can only smart compare with other SmartSortAtom"

        left_value = value
        right_value = other.value

        if left_value.class == right_value.class
          left_value <=> right_value
        elsif left_value.is_a?(Gem::Version)
          if right_value.is_a?(Numeric) && right_value.negative?
            -1
          elsif right_value.is_a?(Integer)
            result = left_value <=> Gem::Version.new(right_value)

            if result == 0
              1
            else
              result
            end
          elsif index == 0
            -1
          else
            1
          end
        elsif left_value.is_a?(Float)
          if right_value.is_a?(Integer)
            result = left_value <=> right_value

            if result == 0
              1
            else
              result
            end
          elsif right_value.is_a?(Gem::Version)
            -1
          elsif index == 0
            -1
          else
            1
          end
        elsif left_value.is_a?(Integer)
          if right_value.is_a?(Float)
            result = left_value <=> right_value

            if result == 0
              -1
            else
              result
            end
          elsif left_value.negative?
            -1
          elsif right_value.is_a?(Gem::Version)
            result = Gem::Version.new(left_value) <=> right_value

            if result == 0
              -1
            else
              result
            end
          elsif index == 0
            -1
          else
            1
          end
        else
          1
        end
      end

      def self.parse(string)
        index_offset = 0

        # Loosely based on http://stackoverflow.com/a/4079031
        # /(?<=^|\s)[-][\d\.]+|[\d\.]+|.+?/
        # /(?<=^|\s)[-][\d\.]+|[\d\.]+|[^\d\.\-]+|[^\d\.]+/
        string.scan(/\d+(?:\.\d+){2,}|(?:(?<=^|\s)[-])?\d+(?:\.\d+)?|.+?/).each_with_index.map do |atom, index|
          if !atom.match(/[-]?\d+(\.\d+)?/)
            new(normalize_string(atom), index + index_offset)
          elsif !atom.include?('.')
            new(atom.to_i, index + index_offset)
          elsif atom.include?('-')
            new(atom.to_f, index + index_offset)
          else
            new(Gem::Version.new(atom), index + index_offset)
          end
        end
      end

      def self.sort(list)
        list.sort_by{ |item| parse(item) }
      end

    private

      def self.normalize_string(string)
        string = ActiveSupport::Inflector.transliterate(string)
        string = string.downcase
        string
      end
    end
  end
end
