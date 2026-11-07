TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CarIntroPrefs
CarIntroPrefs_FILES = CIRootListController.m
CarIntroPrefs_FRAMEWORKS = UIKit PhotosUI
CarIntroPrefs_PRIVATE_FRAMEWORKS = Preferences
CarIntroPrefs_INSTALL_PATH = /Library/PreferenceBundles
CarIntroPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
