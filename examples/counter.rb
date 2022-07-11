require "./src/essential"


# SCHEMA
# Typically one schema per project, and it would be require'd from each page file.

Visitor = table(:visitors) {
}

Counter = table(:counters) {
  column Visitor
  column Integer, :value, 0
}


# PAGE
# HTML-esque DSL with interactivity primitives and access to the state.

app = page {
  visitor_id = session.fetch(:visitor_id) { Visitor.create.id }
  counter = Counter.find_or_create_by(visitor_id:)

  button(onclick: -> { counter.decrement(:value) }) { text "-1" }
  text { counter.value }
  button(onclick: -> { counter.increment(:value) }) { text "+1" }
}

app.run!
