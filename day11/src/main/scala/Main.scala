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

def parse(input: String): Facility = {
  val floors = input.linesIterator
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
  Facility(
    numMoves = 0,
    floors,
    currentFloor = 0,
    elevatorContents = (None, None)
  )
}

case class Facility(
    numMoves: Int,
    floors: List[List[Item]],
    currentFloor: Int,
    elevatorContents: (Option[Item], Option[Item])
) {
  def isDone: Boolean = floors.init.forall(_.isEmpty) && floors.last.nonEmpty
  def isValid: Boolean = {
    val allItems = currentFloorContents ++ LazyList(
      elevatorContents._1,
      elevatorContents._2
    ).flatten
    val isUnconnectedChip = allItems.exists {
      case Item.Generator(_) => false
      case Item.Microchip(chipName) =>
        !allItems.exists {
          case Item.Generator(genName) if chipName == genName => true
          case _                                              => false
        }
    }
    val isAtLeastOneGenerator = allItems.exists {
      case Item.Generator(_) => true
      case _                 => false
    }
    // if a chip is ever left in the same area as another RTG, and it's not connected to its own RTG,
    // the chip will be fried
    val isInvalid = isUnconnectedChip && isAtLeastOneGenerator
    !isInvalid
  }
  def nextMoves: List[Facility] = {
    var allMoves = List.empty[Facility]

    var elevatorSwaps = List.empty[Facility]
    // 1. try taking stuff off the elevator, either both, or one each
    (elevatorContents: @unchecked) match {
      case (Some(a), Some(b)) =>
        elevatorSwaps = elevatorSwaps ++ List(
          copy(
            elevatorContents = (None, None),
            floors =
              floors.updated(currentFloor, currentFloorContents ++ List(a, b))
          )
        )
    }
    (elevatorContents: @unchecked) match {
      case (Some(a), _) =>
        elevatorSwaps = elevatorSwaps ++ List(
          copy(
            elevatorContents = (None, elevatorContents._2),
            floors =
              floors.updated(currentFloor, currentFloorContents ++ List(a))
          )
        )
    }
    (elevatorContents: @unchecked) match {
      case (_, Some(b)) =>
        elevatorSwaps = elevatorSwaps ++ List(
          copy(
            elevatorContents = (elevatorContents._1, None),
            floors =
              floors.updated(currentFloor, currentFloorContents ++ List(b))
          )
        )
    }
    // 2. could also take any items and move them onto the elevators

    allMoves.distinct.filter(_.isValid)
  }
  private def currentFloorContents = floors(currentFloor)
}

object Main extends App {
  var facility = parse(INPUT)
  println(facility.isValid)
}
