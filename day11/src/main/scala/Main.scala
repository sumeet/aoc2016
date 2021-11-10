import scala.language.postfixOps

private val INPUT = """The first floor contains a strontium generator, a strontium-compatible microchip, a plutonium generator, and a plutonium-compatible microchip.
              |The second floor contains a thulium generator, a ruthenium generator, a ruthenium-compatible microchip, a curium generator, and a curium-compatible microchip.
              |The third floor contains a thulium-compatible microchip.
              |The fourth floor contains nothing relevant.""".stripMargin

private val SAMPLE =
  """The first floor contains a hydrogen-compatible microchip, and a lithium-compatible microchip.
               |The second floor contains a hydrogen generator.
               |The third floor contains a lithium generator.
               |The fourth floor contains nothing relevant.""".stripMargin

enum Item:
  case Generator(name: Char)
  case Microchip(name: Char)

def matches(gen: Item.Generator, chip: Item.Microchip): Boolean = {
  gen.name == chip.name
}

def without1[A](xs: List[A]): Seq[(A, List[A])] = {
  xs.zipWithIndex.map((x, i) =>
    (x, xs.slice(0, i) ++ xs.slice(i + 1, xs.length))
  )
}

def without2[A](xs: List[A]): Seq[(A, A, List[A])] = {
  without1(xs).flatMap((x, ys) => without1(ys).map((y, zs) => (x, y, zs)))
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
        println(stuff)
        stuff
          .split(", ")
          .map(_.split(' '))
          .map(s =>
            if (s(2) == "generator") Item.Generator(s(1)(0))
            else Item.Microchip(s(1)(0))
          )
          .toList
      }
    })
    .toList
  Facility(
    floors,
    currentFloor = 0,
    elevatorContents = (None, None)
  )
}

def isFloorValid(items: List[Item]): Boolean = {
  val isUnconnectedChip = items.exists {
    case Item.Generator(_) => false
    case Item.Microchip(chipName) =>
      !items.exists {
        case Item.Generator(genName) if chipName == genName => true
        case _                                              => false
      }
  }
  val isAtLeastOneGenerator = items.exists {
    case Item.Generator(_) => true
    case _                 => false
  }
  // "if a chip is ever left in the same area as another RTG, and it's not connected to its own RTG,
  // the chip will be fried"
  !isUnconnectedChip || !isAtLeastOneGenerator
}

case class Facility(
    floors: List[List[Item]],
    currentFloor: Int,
    elevatorContents: (Option[Item], Option[Item])
) {
  def isDone: Boolean =
    floors.init.forall(_.isEmpty) && currentFloor == floors.length - 1
  def isValid: Boolean =
    contentsByFloorNo.forall((_, items) => isFloorValid(items))
  private def contentsByFloorNo: Iterator[(Int, List[Item])] = {
    floors.iterator.zipWithIndex.map((floorItems, floorNo) =>
      (
        floorNo,
        if (floorNo == currentFloor) currentFloorContents else floorItems
      )
    )
  }
  def nextMoves: List[Facility] = {
    // can't have an empty elevator, so.
    // move just a single item onto the elevator
    val moveOneItemTemplates = without1(currentFloorContents)
      .map((elItem, rest) =>
        copy(
          elevatorContents = (Some(elItem), None),
          floors = floors.updated(currentFloor, rest)
        )
      )
    // and move 2 items onto the elevator
    val moveTwoItemsTemplates = without2(currentFloorContents)
      .map((elItem1, elItem2, rest) =>
        copy(
          elevatorContents = (Some(elItem1), Some(elItem2)),
          floors = floors.updated(currentFloor, rest)
        )
      )

    val moveItemsDownstairs = if (currentFloor > 0) {
      val moveOneItemDownstairs = moveOneItemTemplates
        .map(fac => fac.copy(currentFloor = currentFloor - 1))
        .filter(_.isValid)
      val moveTwoItemsDownstairs = moveTwoItemsTemplates
        .map(fac => fac.copy(currentFloor = currentFloor - 1))
        .filter(_.isValid)
      if (moveOneItemDownstairs.nonEmpty) moveOneItemDownstairs
      else moveTwoItemsDownstairs
    } else Seq.empty

    val moveItemsUpstairs =
      if (currentFloor < floors.length - 1) {
        val moveOneItemUpstairs = moveOneItemTemplates
          .map(fac => fac.copy(currentFloor = currentFloor + 1))
          .filter(_.isValid)
        val moveTwoItemsUpstairs = moveTwoItemsTemplates
          .map(fac => fac.copy(currentFloor = currentFloor + 1))
          .filter(_.isValid)
        if (moveTwoItemsUpstairs.nonEmpty) moveTwoItemsUpstairs
        else moveOneItemUpstairs
      } else Seq.empty

    (moveItemsDownstairs ++ moveItemsUpstairs).toList
  }
  def closenessScore: Int = contentsByFloorNo
    .map((floorNo, items) => floorNo * floorNo * floorNo * items.length)
    .sum

  // current floor items + the contents of the elevator
  private def currentFloorContents = floors(currentFloor) ++ LazyList(
    elevatorContents._1,
    elevatorContents._2
  ).flatten
}

object Main extends App {
  var initial = parse(INPUT)

  // for part 2
  initial = initial.copy(floors =
    initial.floors.updated(
      0,
      initial.floors.head ++ List(
        Item.Generator('d'),
        Item.Microchip('d'),
        Item.Generator('e'),
        Item.Microchip('e')
      )
    )
  )

  var facilityQ = List(initial)
  var movesCount = 0
  while (!facilityQ.exists(_.isDone)) {
    facilityQ = facilityQ.flatMap(_.nextMoves).distinct
    var facilityQByScore = facilityQ.groupBy(_.closenessScore)
    if (facilityQByScore.size > 4) {
      val scores = facilityQByScore.keys.toList.sorted
      for (score <- scores.slice(0, (scores.length / 3).toInt)) {
        facilityQByScore = facilityQByScore.removed(score)
      }
      facilityQ = facilityQByScore.values.flatten.toList
    }
    movesCount += 1
    pprint.log(movesCount)
  }
  pprint.log(movesCount)
}
