require 'trusty/sorting/atoms/version'
#
# Based on https://makandracards.com/makandra/9185-ruby-natural-sort-strings-with-umlauts-and-other-funny-characters
#
module Trusty
  module Sorting
    class AtomSorter

      LEFT_FIRST  = -1
      RIGHT_FIRST =  1
      BOTH_EQUAL  =  0

      COMPARERS = {}

      # /(?<=^|\s)[-][\d\.]+|[\d\.]+|.+?/
      # /(?<=^|\s)[-][\d\.]+|[\d\.]+|[^\d\.\-]+|[^\d\.]+/
      PATTERNS_RE = /\d+(?:\.\d+){2,}|(?:(?<=^|\s)[-])?\d+(?:\.\d+)?|.+?/
      NUMERIC_RE  = /[-]?\d+(\.\d+)?/

      attr_reader :value, :index

      def initialize(value, index)
        @value, @index = value, index
      end

      def <=>(other)
        other.is_a?(self.class) || raise("#{self.class} can only compare with classes of the same kind")

        self.class.compare_values(self.value, other.value)
      end

      class << self
        def compare_values(left_value, right_value)
          if left_value.class == right_value.class
            left_value <=> right_value
          elsif comparer = COMPARERS[comparer_key_for(left_value.class, right_value.class)]
            comparer.call(left_value, right_value)
          else
            raise "No comparer defined for #{left_value.class} <=> #{right_value.class}"
          end
        end

        # Loosely based on http://stackoverflow.com/a/4079031
        def parse(string)
          string.scan(PATTERNS_RE).each_with_index.map do |atom, index|
            if    !atom.match(NUMERIC_RE) then  new(normalize_string(atom), index)
            elsif !atom.include?('.')     then  new(atom.to_i, index)
            elsif atom.include?('-')      then  new(atom.to_f, index)
            else                                new(Atoms::Version.new(atom), index)
            end
          end
        end

        def sort(list)
          list.sort_by{ |item| parse(item) }
        end

        def add_comparer(left_type, right_type, &comparer)
          COMPARERS[comparer_key_for(left_type, right_type)] = comparer_builder(left_type, right_type, &comparer)
        end

      private

        def normalize_string(string)
          ActiveSupport::Inflector.transliterate(string).downcase
        end

        def comparer_builder(left_type, right_type, &comparer)
          ->(left_value, right_value) do
            if left_value.is_a?(left_type)
              comparer.call(left_value, right_value)
            else
              -comparer.call(right_value, left_value)
            end
          end
        end

        def check_result(left_value, right_value, if_this, then_that)
          result = left_value <=> right_value
          if_this == result ? then_that : result
        end

        def comparer_key_for(*types)
          types.map(&:to_s).sort
        end
      end

      # Default comparers

      add_comparer(Atoms::Version, Integer) do |left_value, right_value|
        right_value.negative? ? RIGHT_FIRST : check_result(left_value, [right_value], BOTH_EQUAL, RIGHT_FIRST)
      end
      add_comparer(Atoms::Version, Float) do |left_value, right_value|
        right_value.negative? ? RIGHT_FIRST : check_result(left_value, Atoms::Version.new(right_value), BOTH_EQUAL, LEFT_FIRST)
      end
      add_comparer(Atoms::Version, String){ |left_value, right_value| right_value[/^\s/] ? RIGHT_FIRST : LEFT_FIRST }
      add_comparer(Integer, Float){ |left_value, right_value| check_result(left_value, right_value, BOTH_EQUAL, LEFT_FIRST) }
      add_comparer(Integer, String){ |left_value, right_value| right_value[/^\s/] ? RIGHT_FIRST : LEFT_FIRST }
      add_comparer(Float, String){ |left_value, right_value| right_value[/^\s/] ? RIGHT_FIRST : LEFT_FIRST }
    end
  end
end
