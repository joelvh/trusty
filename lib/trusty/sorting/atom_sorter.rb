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
        elsif left_value.is_a?(Float)
          if right_value.is_a?(Integer)
            if left_value < 0 || right_value < 0
              if left_value == right_value.to_f
                1
              else
                left_value <=> right_value
              end
            else
              Gem::Version.new(left_value) <=> Gem::Version.new(right_value)
            end
          elsif index == 0
            -1
          else
            1
          end
        elsif left_value.is_a?(Integer)
          if right_value.is_a?(Float)
            if left_value < 0 || right_value < 0
              if left_value.to_f == right_value
                -1
              else
                left_value <=> right_value
              end
            else
              # use version sorting in case there are multiple '.' characters
              Gem::Version.new(left_value) <=> Gem::Version.new(right_value)
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
        string.scan(/(?<=^|\s)[-][\d\.]+|[\d\.]+|.+?/).each_with_index.map do |atom, index|
          if atom.match(/[-]?\d+(\.\d+)?/)
            case atom.count('.')
            when 0
              new(atom.to_i, index + index_offset)
            when 1
              new(atom.to_f, index + index_offset)
            else
              # for strings with multiple decimals, split on '.'
              atom.scan(/\d+|\./).each_with_index.map do |value, value_index|
                if value.match(/\d+/)
                  new(value.to_i, index + value_index)
                else
                  new(value, index + value_index)
                end
              end.tap{ |results| index_offset += results.size - 1 }
            end
          else
            new(normalize_string(atom), index + index_offset)
          end
        end.flatten
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
