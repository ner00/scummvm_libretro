LOCAL_PATH := $(call my-dir)
ROOT_PATH := $(LOCAL_PATH)/../..

# Reset flags not reset to  Makefile.common
DEFINES   :=

include $(ROOT_PATH)/Makefile.common

include $(addprefix $(CORE_DIR)/, $(addsuffix /module.mk,$(MODULES)))
OBJS_MODULES := $(addprefix $(CORE_DIR)/, $(foreach MODULE,$(MODULES),$(MODULE_OBJS-$(MODULE))))

COREFLAGS := $(DEFINES) -D__LIBRETRO__ -DNONSTANDARD_PORT -DUSE_RGB_COLOR -DUSE_OSD -DDISABLE_TEXT_CONSOLE -DFRONTEND_SUPPORTS_RGB565 -DUSE_LIBCO  -DUSE_TRANSLATION -DDETECTION_STATIC -DHAVE_CONFIG_H -DUSE_BINK -DUSE_CXX11 -DUSE_TINYGL
COREFLAGS += -Wno-multichar -Wno-undefined-var-template -Wno-pragma-pack

ifeq ($(TARGET_ARCH),arm)
  COREFLAGS += -D_ARM_ASSEM_
endif

# All current 64-bit archs have 64 in the abi name
ifeq ($(filter $(TARGET_ARCH_ABI),64),64)
  COREFLAGS += -DSIZEOF_SIZE_T=8
else
  COREFLAGS += -DSIZEOF_SIZE_T=4
endif

include $(CLEAR_VARS)
LOCAL_MODULE          := retro
LOCAL_MODULE_FILENAME := scummvm_mainline_libretro
LOCAL_SRC_FILES       := $(DETECT_OBJS:%.o=$(CORE_DIR)/%.cpp)  $(OBJS_DEPS:%.o=%.c) $(OBJS_MODULES:%.o=%.cpp) $(OBJS:%.o=%.cpp)
LOCAL_C_INCLUDES      := $(INCLUDES)
LOCAL_CPPFLAGS        := $(COREFLAGS) -std=c++11
LOCAL_CFLAGS          := $(COREFLAGS)
LOCAL_LDFLAGS         := -Wl,-version-script=$(BUILD_DIR)/link.T
LOCAL_LDLIBS          := -lz -llog
LOCAL_CPP_FEATURES    := rtti
LOCAL_ARM_MODE        := arm
include $(BUILD_SHARED_LIBRARY)
