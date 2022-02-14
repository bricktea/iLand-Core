local addListener = ll.import('ILAPI_AddBeforeEventListener')
addListener('onCreate','AABBCC')
ll.export(function(dict)
    log(dict)
    log('fucku create nmd land.')
    return false
end,'AABBCC')