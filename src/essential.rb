require "./src/essential/table"
require "./src/essential/page"

def table(name, &block)
  Essential::Table.build(name, &block)
end

def page(&block)
  Essential::Page.build(&block)
end
