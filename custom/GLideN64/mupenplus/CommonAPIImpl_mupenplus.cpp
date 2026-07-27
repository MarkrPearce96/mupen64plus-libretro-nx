#include "GLideN64_mupenplus.h"
#include <algorithm>
#include <string>
#include "../PluginAPI.h"
#include <Graphics/Context.h>
#include "../DisplayWindow.h"
#include <Graphics/OpenGLContext/GLFunctions.h>
#include <Graphics/OpenGLContext/opengl_Utils.h>
#include "../RSP.h"

#ifdef ANDROID
#include <sys/stat.h>
#endif

#include <libretro_private.h>

extern retro_environment_t environ_cb;

extern "C" void retroChangeWindow()
{
	dwnd().setToggleFullscreen();
	dwnd().changeWindow();
}

extern size_t rdram_size;
int PluginAPI::InitiateGFX(const GFX_INFO & _gfxInfo)
{
	_initiateGFX(_gfxInfo);

    REG.SP_STATUS = _gfxInfo.SP_STATUS_REG;
    rdram_size = *_gfxInfo.RDRAM_SIZE;

	return TRUE;
}

static
void _cutLastPathSeparator(wchar_t * _strPath)
{
#ifdef ANDROID
	const u32 bufSize = 512;
	char cbuf[bufSize];
	wcstombs(cbuf, _strPath, bufSize);
	std::string pluginPath(cbuf);
	std::string::size_type pos = pluginPath.find_last_of("/");
	mbstowcs(_strPath, pluginPath.c_str(), PLUGIN_PATH_SIZE);
#else
	std::wstring pluginPath(_strPath);
	std::replace(pluginPath.begin(), pluginPath.end(), L'\\', L'/');
	std::wstring::size_type pos = pluginPath.find_last_of(L"/");
	wcscpy(_strPath, pluginPath.substr(0, pos).c_str());
#endif
}

static
void _getWSPath(const char * _path, wchar_t * _strPath)
{
	::mbstowcs(_strPath, _path, PLUGIN_PATH_SIZE);
	_cutLastPathSeparator(_strPath);
}

void getRetroArchDir(wchar_t * _strPath)
{ 
	const char* systemDir = NULL;
	if (!environ_cb(RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY,&systemDir) || !systemDir || !*systemDir)
		systemDir = "./";
	std::string str(systemDir);
	if (str.back() != '/' && str.back() != '\\')
		str += "/";
	str += "Mupen64plus/";
	_getWSPath(str.c_str(), _strPath);
}
void PluginAPI::GetUserDataPath(wchar_t * _strPath)
{
	getRetroArchDir(_strPath);
}

void PluginAPI::GetUserCachePath(wchar_t * _strPath)
{
	getRetroArchDir(_strPath);
}

void PluginAPI::FindPluginPath(wchar_t * _strPath)
{
	if (_strPath == nullptr)
		return;
#ifdef OS_WINDOWS
	GetModuleFileNameW(nullptr, _strPath, PLUGIN_PATH_SIZE);
	_cutLastPathSeparator(_strPath);
#elif defined(OS_LINUX)
	char path[512];
	int res = readlink("/proc/self/exe", path, 510);
	if (res != -1) {
		path[res] = 0;
		_getWSPath(path, _strPath);
	}
#elif defined(OS_MAC_OS_X)
	char path[MAXPATHLEN];
	uint32_t pathLen = MAXPATHLEN * 2;
	if (_NSGetExecutablePath(path, pathLen) == 0) {
		_getWSPath(path, _strPath);
	}
#elif defined(ANDROID)
	GetUserCachePath(_strPath);
#endif
}

#include "../FrameBuffer.h"
#include "../DepthBuffer.h"
#include "../gSP.h"
#include "../gDP.h"

// Called from retro_unserialize after a savestate LOAD completes (GL is
// bound via glsm at that point). The framebuffer/depth caches still hold
// buffers rendered BEFORE the load — under libretro the state can only be
// accepted after the first frame has already drawn — and stale buffers
// composite over the restored game (frozen regions / mixed frames). Drop
// and re-init both caches and dirty the full RSP/RDP state so everything
// rebuilds from the restored RDRAM.
extern "C" void gln64_invalidate_gl_cache(void)
{
	// Frame-boundary resync: called from retro_run right after
	// GLSM_CTL_STATE_BIND re-imposes glsm's tracked GL state behind the
	// cached-function layer's back. See the call site in libretro.c.
	gfxContext.resetCachedState();
}

extern "C" void gln64_reset_framebuffer_state(void)
{
	// Surgical clear only: FrameBuffer_Destroy()/Init() also re-run the
	// overscan/display-geometry init, which mid-session latches wrong
	// window sizes and shrinks the present. Drop the cached color + depth
	// buffers, leave geometry and VI tracking untouched, and dirty the
	// full RSP/RDP state so everything rebuilds from the restored RDRAM.
	// The frontend's GL state save/restore around retro_unserialize changes
	// real GL state behind the cached-function layer's back (observed:
	// viewport left at the present size while the cache still claimed the
	// render size, shrinking all subsequent drawing). Invalidate every
	// cache so the next state call re-asserts with a real GL call.
	gfxContext.resetCachedState();
	frameBufferList().clearBuffers();
	depthBufferList().destroy();
	depthBufferList().init();
	gSP.changed = gDP.changed = 0xFFFFFFFF;
}
