###############################
## Extract package meta-data ##
###############################
# Read the package.xml file.
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/package.xml package_xml_str)

# Find project name.
if(NOT package_xml_str MATCHES "<name>([A-Za-z0-9_]+)</name>")
  message(FATAL_ERROR "Could not parse project name from package.xml. Aborting.")
else()
  set(EXTRACTED_NAME ${CMAKE_MATCH_1})
endif()

# Find project version.
if(NOT package_xml_str MATCHES "<version>([0-9]+.[0-9]+.[0-9]+)</version>")
  message(FATAL_ERROR "Could not parse project version from package.xml. Aborting.")
else()
  set(EXTRACTED_VERSION ${CMAKE_MATCH_1})
endif()

# At this point we either have proper name and version strings,
# or we've errored out with a FATAL_ERROR above.
