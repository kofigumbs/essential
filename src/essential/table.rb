require 'securerandom'
require 'time'

module Essential
  module Table
    Column = Struct.new('Column', :type, :name, :default)

    class Builder
      attr_accessor :name
      attr_accessor :columns

      def initialize(name)
        self.name = name
        self.columns = [
          Column.new('Uuid', :id, -> { SecureRandom.uuid }),
          Column.new('DateTime', :created_at, -> { DateTime.now }),
          Column.new('DateTime', :updated_at, -> { DateTime.now }),
        ]
      end

      def column(type, name = nil, default = nil)
        name ||= type.builder.name.to_s.sub(/s$/, '') + '_id'
        default_proc = default.respond_to?(:call) ? default : -> { default }
        self.columns << Column.new(type, name.to_sym, default_proc)
        self
      end
    end

    class Model
      attr_accessor :builder
      attr_accessor :struct

      def initialize(builder)
        self.builder = builder
        self.struct = Struct.new(builder.name.to_s.capitalize, *builder.columns.map(&:name)).include(Instance)
      end

      def create(**params)
        self.struct.new *builder.columns.map { |column| params[column.name] || column.default[] }
      end

      alias_method :find_or_create_by, :create
    end

    module Instance
      def increment(field)
        self[field] += 1
      end

      def decrement(field)
        self[field] -= 1
      end
    end

    def self.build(name, &block)
      builder = Builder.new(name)
      builder.instance_exec &block
      Model.new builder
    end
  end
end
