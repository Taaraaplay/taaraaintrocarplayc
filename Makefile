TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CarIntro
CarIntro_FILES = Tweak.x
CarIntro_FRAMEWORKS = UIKit AVFoundation
CarIntro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += carintroprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
