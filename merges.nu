cd /home/ubuntu/Gitlab

ls | each {
  |file| cd $file.name
  # git pull

  let merges = (git log --merges --pretty=format:'{"merge-commit": "%H", "parent-hashes": "%P", "message": "%s", "author": "%an", "datetime": "%ad"}' --date=iso) | jq -s | from json

  let enriched_merges = ($merges | each {|merge|
    let parent_hashes = ($merge.parent-hashes | split row " ")

    let merged_from = (if ($parent_hashes | length) > 1 { 
      let first_parent = ($parent_hashes | get 0)
      let second_parent = ($parent_hashes | get 1)
      let lname_rev = (git name-rev --name-only $first_parent | str trim)
      let rname_rev = (git name-rev --name-only $second_parent | str trim)

      {
        first-parent: $lname_rev,
        second-parent: $rname_rev
      }
    } else { 
      {
        first-parent: null,
        second-parent: null
      }
    })


    let parent_hashes_table = (if ($parent_hashes | length) > 1 { 
      {
        l: ($parent_hashes | get 0),
        r: ($parent_hashes | get 1)
      }
    } else {
      {
        l: null,
        r: null,
      }
    })

    let full_message = (git log $merge.merge-commit -n 1)

    {
      repo: $file.name,
      merge-hash: $merge.merge-commit,
      message: $merge.message,
      author: $merge."author",
      datetime: $merge.datetime,
      first-parent: $merged_from.first-parent,
      second-parent: $merged_from.second-parent,
      first-parent-hash: $parent_hashes_table.l,
      second-parent-hash: $parent_hashes_table.r,
      full-message: $full_message
    }
  })

  {
    merges: $enriched_merges
  }
} | flatten | flatten | to json | save /home/ubuntu/.cache/unibank-merges.json

cd -

