require "./src/essential/table"
require "./src/essential/page"

module Essential
  def self.table(name, &block)
    Essential::Table.build(name, &block)
  end

  def self.page(&block)
    Essential::Page.build(&block)
  end
end
