############################################################################
# CMakeLists.txt
# Copyright (C) 2022  Belledonne Communications, Grenoble France
#
############################################################################
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
############################################################################

set(POSTQUANTUMCRYPTOENGINE_TEST_C_SOURCES
	postquantumcryptoengine-tester.c
)
set(POSTQUANTUMCRYPTOENGINE_TEST_CXX_SOURCES
	crypto.cc
)

add_definitions(
	-DBCTBX_LOG_DOMAIN="postquantumcryptoengine"
)

bc_apply_compile_flags(POSTQUANTUMCRYPTOENGINE_TEST_C_SOURCES STRICT_OPTIONS_CPP STRICT_OPTIONS_C)
bc_apply_compile_flags(POSTQUANTUMCRYPTOENGINE_TEST_CXX_SOURCES STRICT_OPTIONS_CPP STRICT_OPTIONS_CXX)

add_executable(pqcrypto-tester ${POSTQUANTUMCRYPTOENGINE_TEST_C_SOURCES} ${POSTQUANTUMCRYPTOENGINE_TEST_CXX_SOURCES})
set_target_properties(pqcrypto-tester PROPERTIES LINKER_LANGUAGE CXX)

target_link_libraries(pqcrypto-tester PRIVATE bctoolbox bctoolbox-tester postquantumcryptoengine)

add_test(NAME pqcrypto-tester COMMAND pqcrypto-tester)

install(TARGETS pqcrypto-tester
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
	ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
	PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)
