val INPUT = """The first floor contains a strontium generator, a strontium-compatible microchip, a plutonium generator, and a plutonium-compatible microchip.
              |The second floor contains a thulium generator, a ruthenium generator, a ruthenium-compatible microchip, a curium generator, and a curium-compatible microchip.
              |The third floor contains a thulium-compatible microchip.
              |The fourth floor contains nothing relevant.""".stripMargin

enum Item:
  case Generator(name: String)
  case Microchip(name: String)

def matches(gen: Item.Generator, chip: Item.Microchip): Boolean = {
  gen.name == chip.name
}

def parse(input: String): List[List[Item]] = {
  input.linesIterator
    .map(line => {
      var stuff = line.split(" contains ", 2)(1)
      stuff = stuff.replace("and ", "")
      stuff = stuff.replace("-compatible", "")
      stuff = stuff.stripSuffix(".")
      if (stuff == "nothing relevant") {
        List.empty
      } else {
        stuff
          .split(", ")
          .map(_.split(' '))
          .map(s =>
            if (s(2) == "generator") Item.Generator(s(1))
            else Item.Microchip(s(1))
          )
          .toList
      }
    })
    .toList
}

object Main extends App {
  val destFloor = 3
  val floors = parse(INPUT)
  var currentFloor = 0
  var numMoves = 0

  def isDone: Boolean = floors.init.forall(_.isEmpty) && floors.last.nonEmpty

  while (!isDone) {}

  println(floors)
  println(isDone)
}
