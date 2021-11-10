ThisBuild / version := "0.1.0-SNAPSHOT"

ThisBuild / scalaVersion := "3.1.0"

lazy val root = (project in file("."))
  .settings(
    name := "day11"
  )

libraryDependencies += "com.lihaoyi" %% "pprint" % "0.6.6"