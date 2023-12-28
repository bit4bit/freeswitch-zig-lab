#include <test/switch_test.h>

FST_CORE_BEGIN("conf")
{
  FST_MODULE_BEGIN(mod_wren, mod_wren_test)
    {
      FST_SETUP_BEGIN()
        {
          fst_requires_module("mod_wren");
        }
      FST_SETUP_END();

      FST_TEARDOWN_BEGIN()
        {
        }
      FST_TEARDOWN_END();
    }
  FST_MODULE_END();
}
FST_CORE_END();
