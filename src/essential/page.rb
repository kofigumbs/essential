require "securerandom"
require "sinatra/base"

module Essential
  module Page
    class Lazy
      attr_accessor :block

      def initialize(block)
        self.block = block
      end

      def to_s
        block.call
      end
    end

    class Text
      attr_accessor :content

      def initialize(content)
        self.content = content
      end

      def to_html(indent)
        ' '*indent + "#{content.to_s}\n"
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

      def dig(*identifiers)
        identifiers.empty? ? self : children.dig(*identifiers)
      end

      def to_html(indent)
        ' '*indent + "<#{name}#{attributes.map { |(k, v)| " #{k}='#{v}'" }.join}>\n" \
          + children.map { |c| c.to_html(indent + 2) }.join \
          + ' '*indent + "</#{name}>\n"
      end

      def to_s
        to_html 0
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

      def lazy(&block)
        Lazy.new(block)
      end

      def text(content)
        Text.new(content).tap { |el| children.push(el) }
      end

      def onclick(&block)
        ["essential-onclick", listener_id(block)]
      end

      def button(*attributes, &block)
        node :button, attributes, &block
      end

      def node(name, attributes, &block)
        Element.new(name, attributes).tap do |el|
          children.push(el)
          path.push(children.count - 1)
          block.call if block_given?
          path.pop
        end
      end

      def children
        tree.dig(*path).children
      end

      def listener_id(listener)
        SecureRandom.hex(3).tap { |id| listeners[id] = listener }
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
              #{builder.tree}
              <script src='/essential.js'></script>
            </body>
          HTML
        end
        get "/essential/event" do
          builder.listeners[params[:id]].call
          builder.tree.to_s
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
