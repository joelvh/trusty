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

      attr_reader :value, :index

      def initialize(value, index)
        @value = value
        @index = index
      end

      def <=>(other)
        other.is_a?(self.class) || raise("#{self.class} can only compare with classes of the same kind")

        self.class.compare_values(self.value, other.value)
      end

      class << self
        def compare_values(left_value, right_value)
          if left_value.class == right_value.class
            left_value <=> right_value
          else
            if comparer = COMPARERS[comparer_key_for(left_value, right_value)]
              comparer.call(left_value, right_value)
            else
              raise "No comparer defined for #{left_value.class} <=> #{right_value.class}"
            end
          end
        end

        def old_compare_values(left_value, right_value)
          if left_value.class == right_value.class
            left_value <=> right_value
          elsif left_value.is_a?(Gem::Version)
            if right_value.is_a?(Numeric) && right_value.negative?
              LEFT_FIRST
            elsif right_value.is_a?(Integer)
              check_result(left_value, Gem::Version.new(right_value), BOTH_EQUAL, RIGHT_FIRST)
            elsif right_value[/^\s/]
              RIGHT_FIRST
            else
              LEFT_FIRST
            end
          elsif left_value.is_a?(Float)
            if right_value.is_a?(Integer)
              check_result(left_value, right_value, BOTH_EQUAL, RIGHT_FIRST)
            elsif right_value.is_a?(Gem::Version)
              LEFT_FIRST
            elsif right_value[/^\s/]
              RIGHT_FIRST
            else
              LEFT_FIRST
            end
          elsif left_value.is_a?(Integer)
            if right_value.is_a?(Float)
              check_result(left_value, right_value, BOTH_EQUAL, LEFT_FIRST)
            elsif left_value.negative?
              LEFT_FIRST
            elsif right_value.is_a?(Gem::Version)
              check_result(Gem::Version.new(left_value), right_value, BOTH_EQUAL, LEFT_FIRST)
            elsif right_value[/^\s/]
              RIGHT_FIRST
            else
              LEFT_FIRST
            end
          elsif left_value[/^\s/]
            LEFT_FIRST
          else
            RIGHT_FIRST
          end
        end

        # Loosely based on http://stackoverflow.com/a/4079031
        def parse(string)
          # /(?<=^|\s)[-][\d\.]+|[\d\.]+|.+?/
          # /(?<=^|\s)[-][\d\.]+|[\d\.]+|[^\d\.\-]+|[^\d\.]+/
          numbers_re = /\d+(?:\.\d+){2,}|(?:(?<=^|\s)[-])?\d+(?:\.\d+)?|.+?/

          string.scan(numbers_re).each_with_index.map do |atom, index|
            if !atom.match(/[-]?\d+(\.\d+)?/)
              new(normalize_string(atom), index)
            elsif !atom.include?('.')
              new(atom.to_i, index)
            elsif atom.include?('-')
              new(atom.to_f, index)
            else
              new(Gem::Version.new(atom), index)
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
            unless left_value.is_a?(left_type)
              swapped = true
              left_value, right_value = right_value, left_value
            end

            result = comparer.call(left_value, right_value)
            result = -result if swapped
            result
          end
        end

        def check_result(left_value, right_value, if_value, then_value)
          result = left_value <=> right_value
          result = then_value if result == if_value
          result
        end

        def comparer_key_for(left, right)
          [left, right].map{ |item| item.class == Class ? item.name : item.class.name }.sort
        end
      end

      # Default comparers

      add_comparer(Gem::Version, Integer) do |left_value, right_value|
        right_value.negative? ? RIGHT_FIRST : check_result(left_value, Gem::Version.new(right_value), BOTH_EQUAL, RIGHT_FIRST)
      end
      add_comparer(Gem::Version, Float) do |left_value, right_value|
        right_value.negative? ? RIGHT_FIRST : check_result(left_value, Gem::Version.new(right_value), BOTH_EQUAL, LEFT_FIRST)
      end
      add_comparer(Gem::Version, String){ |left_value, right_value| right_value[/^\s/] ? RIGHT_FIRST : LEFT_FIRST }
      add_comparer(Integer, Float){ |left_value, right_value| check_result(left_value, right_value, BOTH_EQUAL, LEFT_FIRST) }
      add_comparer(Integer, String){ |left_value, right_value| right_value[/^\s/] ? RIGHT_FIRST : LEFT_FIRST }
      add_comparer(Float, String){ |left_value, right_value| right_value[/^\s/] ? RIGHT_FIRST : LEFT_FIRST }
    end
  end
end
