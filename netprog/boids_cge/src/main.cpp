#define OLC_PGE_APPLICATION
#include "olcConsoleGameEngine.h"

class BoidsDemo : public olcConsoleGameEngine
{
public:
    BoidsDemo()
    {
        m_sAppName = L"Boids Lite (CGE)";
    }

    virtual bool OnUserCreate() override
    {
        // Initialization step (boids will go here)
        return true;
    }

    virtual bool OnUserUpdate(float fElapsedTime) override
    {
        // For now, just draw something so we know CGE works
        ClearScreen();

        DrawString(2, 2, L"CGE Test OK! fElapsedTime=" + std::to_wstring(fElapsedTime));

        return true;
    }
};

int main()
{
    BoidsDemo demo;

    // Construct console: width, height, font width, font height
    if (demo.ConstructConsole(120, 40, 8, 8) == 0)
        return 0;

    demo.Start();
    return 0;
}
