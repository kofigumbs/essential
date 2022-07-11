### Essential is an attempt to create a full-stack application,
### including a database, with as little application code as possible.
### This example works! The implementation cuts a bunch of corners,
### but this example is runable and does show an interactive counter!
###
###     git clone https://github.com/kofigumbs/essential
###     cd essential
###     bundle install
###     ruby examples/counter.rb


require "./src/essential"


# SCHEMA
#
# Typically one schema per project, and it would be require'd from each page.
# Essential would run the `CREATE TABLE IF NOT EXISTS` automatically on startup.

Visitor = table(:visitors) {
}

Counter = table(:counters) {
  column Visitor
  column Integer, :value, 0
}


# PAGE
#
# HTML-esque DSL with interactivity primitives and access to the state.
# Eventually, this would probably include layout helpers as well.
# Event procs get transformed into data-attributes that are automatically
# managed by Essential.

app = page {
  visitor_id = session.fetch(:visitor_id) { Visitor.create.id }
  counter = Counter.find_or_create_by(visitor_id:)

  button(onclick: -> { counter.decrement(:value) }) { text "-1" }
  text { counter.value }
  button(onclick: -> { counter.increment(:value) }) { text "+1" }
}

app.run!
