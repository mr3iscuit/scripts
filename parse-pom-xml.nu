export def pp [file] {
  let pom = open $file
  let deps = $pom | get content | where tag == dependencies | first 1 | get content.0.content 
  | each { |dep| 

    let version = $dep | where tag == version 
    let scope = $dep | where tag == scope 

    let artifactId = $dep | where tag == artifactId | get content.0.content.0
    let groupId = $dep | where tag == groupId | get content.0.content.0

    {
      groupId: $groupId,
      artifactId: $artifactId,
      version: (if ($version | length) > 0 { $version.0.content.0.content } else { null }),
      scope: (if ($scope | length) > 0 { $scope.0.content.0.content } else { null })
    }

  } | each { | dep | 

    mut gradleScobe = match $dep.scope {
      "runtime" => "Implementation",
      "test" => "testImplmenetation",
      _ => "Implementation"
    }

    {
      ...($dep),
      gradle: $"($gradleScobe) \"($dep.groupId):($dep.artifactId)\""

    }
  }

  return {
    pom: $pom
    deps: $deps,
  }
}
