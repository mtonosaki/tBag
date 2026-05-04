rm ~/Library/Containers/com.tomarika.tbag/Data/Library/Application\ Support/default.store
rm ~/Library/Containers/com.tomarika.tbag/Data/Library/Application\ Support/default.store-shm
rm ~/Library/Containers/com.tomarika.tbag/Data/Library/Application\ Support/default.store-wal

echo .
echo 次のURLから [Reset Environment]をクリックして iCloudのデータも削除してください。
echo .
CLOUDKITURL="https://icloud.developer.apple.com/dashboard/database/teams/42235ECE62/containers/iCloud.com.tomarika.tBag.privatedb/environments/DEVELOPMENT/records?using=queryRecords&database=public&zone=_defaultZone"
echo ${CLOUDKITURL}
echo ${CLOUDKITURL} | pbcopy

