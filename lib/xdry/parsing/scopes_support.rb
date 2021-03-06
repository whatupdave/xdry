
module XDry

  class Scope

    attr_reader :model
    attr_reader :children

    def initialize
      @children = []
      self.class.child_collections.each do |var_name|
        instance_variable_set("@#{var_name}", [])
      end
    end

    def bind model
      raise StandardError, "#{self} already bound to #{@model} when trying to bind to #{model}" unless @model.nil?
      @model = model
      self
    end

    def assert_bound!
      raise StandardError, "#{self.class.name} hasn't been bound to a model" if @model.nil?
    end

    def parser
      @parser ||= create_parser
    end

    def subscope_for node
      if subscope_class = self.class.child_subscope_table[node.class]
        subscope_class.new(self, node)
      else
        nil
      end
    end

    def ends_after? node
      self.class.stop_children.include? node.class
    end

    def << child
      raise StandardError, "#{self.class.name} hasn't been bound to a model, but is trying to accept a child #{child}" if @model.nil?
      @children << child
      @model << child
      child_added child
    end

    def child_added child
      (self.class.child_action_table[child.class] || []).each { |action| action.call(self, child) }
    end

    def to_s
      "#{self.class.name}:#{@model}"
    end

    def parent_scopes
      []
    end

    def all_scopes
      parent_scopes + [self]
    end

  protected

    def create_parser
      return self.class.parser_class.new(self) if self.class.parser_class
      raise StandardError, "#{self.class.name} does not override create_parser"
    end

    class << self

      attr_reader :parser_class

      def parse_using parser_class
        @parser_class = parser_class
      end

      # on NSome, :pop, :store_into => :my_var
      # on NOther, :start => SOther
      # on NAwesome, :add_to => :awesomes
      def on child_class, *args
        options = args.last.is_a?(Hash) ? args.pop : {}
        if args.include? :pop
          stop_children << child_class
        end
        if options[:start]
          child_subscope_table[child_class] = options[:start]
        end
        if var_name = options[:store_into]
          (child_action_table[child_class] ||= []) << lambda do |instance, child|
            instance.send(:instance_variable_set, "@#{var_name}", child)
          end
          attr_reader :"#{var_name}"
        end
        if coll_name = options[:add_to]
          (child_action_table[child_class] ||= []) << lambda do |instance, child|
            instance.send(:instance_variable_get, "@#{coll_name}") << child
          end
          child_collections << coll_name
          attr_reader :"#{coll_name}"
        end
      end

      def stop_children
        @stop_children ||= []
      end

      def child_subscope_table
        @child_subscope_table ||= {}
      end

      def child_action_table
        @child_action_table ||= {}
      end

      def child_collections
        @child_collections ||= []
      end

    end

  end

  class ChildScope < Scope

    attr_reader :start_node
    attr_reader :parent_scope

    def initialize parent_scope, start_node
      super()
      @parent_scope = parent_scope
      @start_node = start_node
    end

    def parent_scopes
      parent_scope.all_scopes
    end

  end

end
