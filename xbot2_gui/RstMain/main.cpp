#include "rstapp.h"

int main(int argc, char *argv[])
{
    return rst::runApp(argc, argv, "Robosintesi GUI", "RstMain",
                       {XBOT2_GUI_VERSION_MAJOR, XBOT2_GUI_VERSION_MINOR, XBOT2_GUI_VERSION_PATCH});
}
