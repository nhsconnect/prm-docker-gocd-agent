#!/bin/bash

# Cleans up space on the GoCD agents, skips dojo images
# Depends on
# - Docker CLI
# - jq

DELETE_IMAGES_OLDER_THAN_DAYS="${DELETE_IMAGES_OLDER_THAN_DAYS:-180}"

image_ids=$(docker images -qa)
for image_id in $image_ids
do
  if docker inspect $image_id | jq -r .[0].RepoTags | grep -q dojo; then
    echo "$image_id is a dojo image, not deleting"
  else
    date_created=$(docker inspect $image_id | jq -r .[0].Created | awk -F'T' '{print $1}')
    if [[ $date_created == "null" ]]; then
	continue
    fi
    days_since_created=$((($(date +%s)-$(date +%s --date "$date_created"))/(3600*24)))
    if [[ $days_since_created -gt $DELETE_IMAGES_OLDER_THAN_DAYS ]]; then
      echo "$image_id to be deleted"
      docker rmi -f $image_id
    else
      echo "$image_id will not be deleted"
    fi
  fi
done

docker volume prune -f
