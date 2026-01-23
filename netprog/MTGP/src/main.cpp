#include <iostream>
#include <unistd.h>
#include <ncurses.h>
enum AppState : char {
  Exit = '0',
  MainMenu    = 'i',
  LoadFile    = '1',
  SaveFile    = '2',
  ShellOut    = '3',
  AddEntry    = '4',
  EditEntry   = '5',
  RemoveEntry = '6',
  PrintVector = '7'
};  
AppState STATE{ AppState::MainMenu };
void MainMenu() {
  char input = 'i';
  switch(STATE)
  {
    case AppState::Exit:

      break;
    case AppState::MainMenu:
      while(STATE==AppState::MainMenu)
      {
        std::cout << "===== MAIN MENU =====\n";
        std::cout << " Load File    (1)\n";
        std::cout << " Save File    (2)\n";
        std::cout << " Shell Out    (3)\n";
        std::cout << " Add Entry    (4)\n";
        std::cout << " Edit Entry   (5)\n";
        std::cout << " Remove Entry (6)\n";
        std::cout << " Print Vector (7)\n";
        std::cout << " Exit         (0)\n";
        std::cout << "Enter option: ";
        std::cin >> input;
        std::string fileName{""};
        switch(input)
        {
          case '1':
            STATE = AppState::LoadFile;
            std::cout << "\nEnter filename\n";
            std::cin >> fileName;
            if(LoadFile(fileName))
            {
              std::cout << "File was succesfully loaded.\n";
            }
            else
            {
              std::string s = std::format("Error: Unable to load from file {}", fileName);
              std::cout << s;
            }
            break;
          case '2':
            STATE = AppState::SaveFile;
            break;
          case '3':
            STATE = AppState::ShellOut;
            break;
          case '4':
            STATE = AppState::AddEntry;
            break;
          case '5':
            STATE = AppState::EditEntry;
            break;
          case '6':
            STATE = AppState::RemoveEntry;
            break;
          case '7':
            STATE = AppState::PrintVector;
            break;
          case '0':
            STATE = AppState::Exit;
        }
      };
      break;
    case AppState::LoadFile:

      break;
    case AppState::SaveFile:

      break;
    case AppState::ShellOut:

      break;
    default:
      std::cout << "Error invalid input\n";
    }
}
int main() {
  bool b_keepRunning = true;
  while(b_keepRunning)
  {
    MainMenu();
  };

  return 0;
}
