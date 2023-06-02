# Copyright 2010, 2020, Olivier Stasse, Guilhem Saurel, JRL, CNRS/AIST,
# LAAS-CNRS See LICENSE file.

cmake_minimum_required(VERSION 3.1)

# Project properties
set(PROJECT_ORG stack-of-tasks)
set(PROJECT_NAME jrl-walkgen)
set(PROJECT_DESCRIPTION "Walking pattern generator for Humanoids")
set(PROJECT_URL "https://github.com/${PROJECT_ORG}/${PROJECT_NAME}")

# Project options
option(USE_LSSOL "Do you want to use the solver lssol?" OFF)
option(USE_QUADPROG "Do you want to use the solver eigen-quadprog?" ON)
option(SUFFIX_SO_VERSION "Suffix library name with its version" ON)
option(FULL_BUILD_TESTING "Complete and long testing" OFF)

# Project configuration
set(PROJECT_USE_CMAKE_EXPORT TRUE)
set(CXX_DISABLE_WERROR TRUE)
set(DOXYGEN_USE_MATHJAX YES)

# JRL-cmakemodule setup
include(cmake/base.cmake)

# Project definition
compute_project_args(PROJECT_ARGS LANGUAGES CXX C)
project(${PROJECT_NAME} ${PROJECT_ARGS})

# Project dependencies
add_project_dependency(LAPACK REQUIRED)
add_project_dependency(pinocchio REQUIRED)

# Handle OS specificities
include(CheckIncludeFile)
check_include_file("sys/time.h" SYS_TIME_H)
if(SYS_TIME_H)
  add_definitions("-DHAVE_SYS_TIME_H")
endif(SYS_TIME_H)

# TODO kinda dirty patch to find lssol for now using ADD_OPTIONAL_DEPENDENCY
# prevents the creation of classic variables such as ${PKG}_FOUND hence we use
# ADD_REQUIRED_DEPENDENCY to get the data
if(USE_LSSOL)
  add_required_dependency("lssol >= 0.1.0")
endif(USE_LSSOL)

if(USE_QUADPROG)
  add_project_dependency(eigen-quadprog REQUIRED)
endif(USE_QUADPROG)

# Add aggressive optimization flags in release mode.
if(CMAKE_COMPILER_IS_GNUCXX)
  set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG ")
endif(CMAKE_COMPILER_IS_GNUCXX)

# Main Library

set(${PROJECT_NAME}_HEADERS
    include/jrl/walkgen/patterngeneratorinterface.hh
    include/jrl/walkgen/pgtypes.hh include/jrl/walkgen/pinocchiorobot.hh)

set(${PROJECT_NAME}_SOURCES
    src/RobotDynamics/pinocchiorobot.cpp
    src/FootTrajectoryGeneration/FootTrajectoryGenerationAbstract.cpp
    src/FootTrajectoryGeneration/FootTrajectoryGenerationStandard.cpp
    src/FootTrajectoryGeneration/FootTrajectoryGenerationMultiple.cpp
    src/FootTrajectoryGeneration/LeftAndRightFootTrajectoryGenerationMultiple.cpp
    src/FootTrajectoryGeneration/OnLineFootTrajectoryGeneration.cpp
    src/GlobalStrategyManagers/CoMAndFootOnlyStrategy.cpp
    src/GlobalStrategyManagers/GlobalStrategyManager.cpp
    src/GlobalStrategyManagers/DoubleStagePreviewControlStrategy.cpp
    src/Mathematics/AnalyticalZMPCOGTrajectory.cpp
    src/Mathematics/ConvexHull.cpp
    src/Mathematics/FootConstraintsAsLinearSystem.cpp
    # src/Mathematics/FootConstraintsAsLinearSystemForVelRef.cpp
    src/Mathematics/FootHalfSize.cpp
    src/Mathematics/OptCholesky.cpp
    src/Mathematics/Bsplines.cpp
    src/Mathematics/Polynome.cpp
    src/Mathematics/PolynomeFoot.cpp
    src/Mathematics/PLDPSolver.cpp
    src/Mathematics/qld.cpp
    src/Mathematics/StepOverPolynome.cpp
    src/Mathematics/relative-feet-inequalities.cpp
    src/Mathematics/intermediate-qp-matrices.cpp
    src/PreviewControl/PreviewControl.cpp
    src/PreviewControl/OptimalControllerSolver.cpp
    src/PreviewControl/ZMPPreviewControlWithMultiBodyZMP.cpp
    src/PreviewControl/LinearizedInvertedPendulum2D.cpp
    src/PreviewControl/rigid-body.cpp
    src/PreviewControl/rigid-body-system.cpp
    src/PreviewControl/SupportFSM.cpp
    src/ZMPRefTrajectoryGeneration/ZMPRefTrajectoryGeneration.cpp
    src/ZMPRefTrajectoryGeneration/ZMPDiscretization.cpp
    src/ZMPRefTrajectoryGeneration/ZMPQPWithConstraint.cpp
    src/ZMPRefTrajectoryGeneration/ZMPConstrainedQPFastFormulation.cpp
    src/ZMPRefTrajectoryGeneration/ZMPVelocityReferencedQP.cpp
    src/ZMPRefTrajectoryGeneration/OrientationsPreview.cpp
    src/ZMPRefTrajectoryGeneration/AnalyticalMorisawaAbstract.cpp
    src/ZMPRefTrajectoryGeneration/AnalyticalMorisawaCompact.cpp
    src/ZMPRefTrajectoryGeneration/FilteringAnalyticalTrajectoryByPreviewControl.cpp
    src/ZMPRefTrajectoryGeneration/problem-vel-ref.cpp
    src/ZMPRefTrajectoryGeneration/qp-problem.cpp
    src/ZMPRefTrajectoryGeneration/generator-vel-ref.cpp
    src/ZMPRefTrajectoryGeneration/mpc-trajectory-generation.cpp
    src/ZMPRefTrajectoryGeneration/DynamicFilter.cpp
    # src/MultiContactRefTrajectoryGeneration/MultiContactHirukawa.cc
    src/MotionGeneration/StepOverPlanner.cpp
    src/MotionGeneration/CollisionDetector.cpp
    src/MotionGeneration/WaistHeightVariation.cpp
    src/MotionGeneration/UpperBodyMotion.cpp
    src/MotionGeneration/GenerateMotionFromKineoWorks.cpp
    src/MotionGeneration/ComAndFootRealizationByGeometry.cpp
    src/StepStackHandler.cpp
    src/PatternGeneratorInterfacePrivate.cpp
    src/SimplePlugin.cpp
    src/SimplePluginManager.cpp
    src/pgtypes.cpp
    src/Clock.cpp
    src/portability/gettimeofday.cc
    src/privatepgtypes.cpp)

if(USE_QUADPROG)
  set(${PROJECT_NAME}_SOURCES
      ${${PROJECT_NAME}_SOURCES}
      src/ZMPRefTrajectoryGeneration/ZMPVelocityReferencedSQP.cpp
      src/ZMPRefTrajectoryGeneration/nmpc_generator.cpp)
endif(USE_QUADPROG)

add_library(${PROJECT_NAME} SHARED ${${PROJECT_NAME}_SOURCES}
                                   ${${PROJECT_NAME}_HEADERS})
target_include_directories(
  ${PROJECT_NAME}
  PRIVATE $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src>
          $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src/FootTrajectoryGeneration>
  PUBLIC $<INSTALL_INTERFACE:include>)
target_link_libraries(${PROJECT_NAME} ${LAPACK_LIBRARIES} pinocchio::pinocchio)
if(USE_QUADPROG)
  target_compile_definitions(${PROJECT_NAME} PUBLIC USE_QUADPROG=1)
endif(USE_QUADPROG)

if(SUFFIX_SO_VERSION)
  set_target_properties(${PROJECT_NAME} PROPERTIES SOVERSION ${PROJECT_VERSION})
endif(SUFFIX_SO_VERSION)

if(UNIX AND NOT APPLE)
  set_target_properties(
    ${PROJECT_NAME}
    PROPERTIES
      COMPILE_FLAGS
      "-msse -msse2 -msse3 -march=core2 -mfpmath=sse -fivopts -ftree-loop-im -fipa-pta "
  )
endif(UNIX AND NOT APPLE)

if(USE_QUADPROG)
  target_link_libraries(${PROJECT_NAME} eigen-quadprog::eigen-quadprog)
endif(USE_QUADPROG)

install(
  TARGETS ${PROJECT_NAME}
  EXPORT ${TARGETS_EXPORT_NAME}
  DESTINATION lib)

add_subdirectory(tests)

install(FILES package.xml DESTINATION share/${PROJECT_NAME})
install(DIRECTORY urdf DESTINATION share/${PROJECT_NAME})
install(DIRECTORY srdf DESTINATION share/${PROJECT_NAME})
