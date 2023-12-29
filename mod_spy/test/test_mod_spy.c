#include <test/switch_test.h>

FST_CORE_BEGIN("conf")
{
  FST_MODULE_BEGIN(mod_spy, mod_spy_test)
    {
      FST_SETUP_BEGIN()
        {
          fst_requires_module("mod_spy");
        }
      FST_SETUP_END();

      FST_TEST_BEGIN(rundemo)
        {
          switch_stream_handle_t stream = { 0 };

          SWITCH_STANDARD_STREAM(stream);

          fst_check(switch_api_execute("zigrun", "demo", NULL, &stream) == SWITCH_STATUS_SUCCESS);

          fst_check(strstr(stream.data, "demo") == stream.data);
          free(stream.data);
        }
      FST_TEST_END();

      FST_TEARDOWN_BEGIN()
        {
        }
      FST_TEARDOWN_END();
    }
  FST_MODULE_END();
}
FST_CORE_END();
