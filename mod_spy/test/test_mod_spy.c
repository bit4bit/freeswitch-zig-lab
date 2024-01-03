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

      FST_TEST_BEGIN(dump_hash)
        {
          switch_stream_handle_t stream = { 0 };

          SWITCH_STANDARD_STREAM(stream);

          fst_check(switch_api_execute("userspy_show", "userspy_show", NULL, &stream) == SWITCH_STATUS_SUCCESS);

          fst_check_string_has(stream.data, "total spy");
        }
      FST_TEST_END();


      FST_SESSION_BEGIN(spy_a_user)
        {
          fst_check(switch_core_session_execute_application(fst_session, "userspy", "12346") == SWITCH_STATUS_SUCCESS);
        }
      FST_SESSION_END();

      FST_SESSION_BEGIN(function_event_handler)
        {
          switch_event_t *event;
          fst_check(switch_event_create(&event, SWITCH_EVENT_CHANNEL_BRIDGE) == SWITCH_STATUS_SUCCESS);
          switch_event_fire(&event);
          sleep(1);
          // TODO: how to check changes in function `event_handler`?
        }
      FST_SESSION_END();

      FST_TEARDOWN_BEGIN()
        {
        }
      FST_TEARDOWN_END();
    }
  FST_MODULE_END();
}
FST_CORE_END();
