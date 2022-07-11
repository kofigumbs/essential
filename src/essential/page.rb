require "securerandom"
require "sinatra/base"

module Essential
  module Page
    class Text
      attr_accessor :block

      def initialize(block)
        self.block = block
      end

      def to_html(indent)
        ' '*indent + "#{self.block.call}\n"
      end
    end

    class Element
      attr_accessor :name
      attr_accessor :attributes
      attr_accessor :children

      def initialize(name, attributes)
        self.name = name
        self.attributes = attributes
        self.children = []
      end

      def dig(name, *identifiers)
        x = case name
            when :attributes then self.attributes
            when :children then self.children
            end
        identifiers.empty? ? x : x.dig(*identifiers)
      end

      def to_html(indent = 0)
        ' '*indent + "<#{self.name}#{self.attributes.map { |(k, v)| " #{k}='#{v}'" }.join}>\n" \
          + self.children.map { |c| c.to_html(indent + 2) }.join \
          + ' '*indent + "</#{self.name}>\n"
      end
    end

    class Builder
      attr_accessor :listeners
      attr_accessor :session
      attr_accessor :path
      attr_accessor :tree

      def initialize
        self.listeners = {}
        self.session = {}
        self.path = []
        self.tree = Element.new(:main, [])
      end

      def text(text = nil, &block)
        self.append Text.new(block_given? ? block : -> { text })
      end

      def button(**attributes, &block)
        self.node :button, **attributes, &block
      end

      def node(name, **attributes, &block)
        attributes = attributes.map do |(k, v)|
          v.respond_to?(:call) ? ["essential-#{k}", listener_id(v)] : [k, v]
        end
        children = self.append Element.new name, attributes
        if block_given?
          self.path.push(:children, children.count - 1)
          block.call
          self.path.pop 2
        end
      end

      def append(child)
        self.tree.dig(*self.path, :children).push child
      end

      def listener_id(listener)
        SecureRandom.hex(3).tap { |id| self.listeners[id] = listener }
      end
    end

    def self.build(&block)
      builder = Builder.new
      builder.instance_exec &block
      Sinatra.new do
        get "/" do
          <<~HTML
            <!DOCTYPE html>
            <body>
              #{builder.tree.to_html}
              <script src='/essential.js'></script>
            </body>
          HTML
        end
        get "/essential/event" do
          builder.listeners[params[:id]].call
          builder.tree.to_html
        end
        get "/essential.js" do
          content_type "application/javascript"
          <<~JS
            document.body.addEventListener('click', async (event) => {
              let id = event.target.getAttribute('essential-onclick');
              if (id) {
                let response = await fetch(`/essential/event?id=${id}`);
                document.body.innerHTML = await response.text();
              }
            });
          JS
        end
      end
    end
  end
end
