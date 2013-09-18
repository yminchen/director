#include "ddMainWindow.h"

#include "ddMacros.h"
#include "ddPythonManager.h"
#include "ddViewManager.h"
#include "ddPropertiesPanel.h"
#include "ddViewMenu.h"

#include "ui_ddMainWindow.h"

#include <QApplication>
#include <QTimer>
#include <QShortcut>

#include <cstdio>


//-----------------------------------------------------------------------------
class ddMainWindow::ddInternal : public Ui::ddMainWindow
{
public:

  ddViewManager* ViewManager;
  ddPropertiesPanel* PropertiesPanel;
  ddPythonManager* PythonManager;
};


//-----------------------------------------------------------------------------
ddMainWindow::ddMainWindow()
{
  this->Internal = new ddInternal;
  this->Internal->setupUi(this);

  this->Internal->ViewManager = new ddViewManager;
  this->Internal->PropertiesPanel = new ddPropertiesPanel;

  this->setCentralWidget(this->Internal->ViewManager);
  this->Internal->PropertiesDock->setWidget(this->Internal->PropertiesPanel);

  this->setWindowTitle("Drake Designer");
  this->connect(this->Internal->ActionQuit, SIGNAL(triggered()), QApplication::instance(), SLOT(quit()));

  this->connect(this->Internal->ShowMatlabConsole, SIGNAL(triggered()), this->Internal->MatlabConsoleDock, SLOT(show()));
  this->Internal->MatlabConsoleDock->hide();

  QTimer::singleShot(0, this, SLOT(startup()));

  this->setCorner(Qt::TopLeftCorner, Qt::LeftDockWidgetArea);
  this->setCorner(Qt::TopRightCorner, Qt::RightDockWidgetArea);
  this->setCorner(Qt::BottomLeftCorner, Qt::LeftDockWidgetArea);
  this->setCorner(Qt::BottomRightCorner, Qt::RightDockWidgetArea);

  this->setupViewMenu();
}

//-----------------------------------------------------------------------------
ddMainWindow::~ddMainWindow()
{
  delete this->Internal;
}

//-----------------------------------------------------------------------------
ddViewManager* ddMainWindow::viewManager() const
{
  return this->Internal->ViewManager;
}

//-----------------------------------------------------------------------------
ddPropertiesPanel* ddMainWindow::propertiesPanel() const
{
  return this->Internal->PropertiesPanel;
}

//-----------------------------------------------------------------------------
QToolBar* ddMainWindow::toolBar() const
{
  return this->Internal->MainToolBar;
}

//-----------------------------------------------------------------------------
void ddMainWindow::handleCommandLineArgs()
{
  QStringList args = QApplication::instance()->arguments();
  ddNotUsed(args);
}

//-----------------------------------------------------------------------------
void ddMainWindow::startup()
{
  this->handleCommandLineArgs();

  this->setupPython();
  QString startupScript = this->Internal->PythonManager->appSitePackagesDir() + "/ddapp/startup.py";
  this->Internal->PythonManager->executeFile(startupScript);
}

//----------------------------------------------------------------------------
void ddMainWindow::setupViewMenu()
{
  ddViewMenu* viewMenu = new ddViewMenu(*this->Internal->ViewMenu, this);
  ddViewMenu* toolbarMenu = new ddViewMenu(*this->Internal->ToolBarMenu, this);

  viewMenu->addWidget(
    this->Internal->ObjectsDock,
    this->Internal->ObjectsDock->windowTitle());

  viewMenu->addWidget(
    this->Internal->PropertiesDock,
    this->Internal->PropertiesDock->windowTitle());

  viewMenu->addWidget(
    this->Internal->MatlabConsoleDock,
    this->Internal->MatlabConsoleDock->windowTitle());

  toolbarMenu->addWidget(
    this->Internal->MainToolBar,
    this->Internal->MainToolBar->windowTitle());

}
//-----------------------------------------------------------------------------
void ddMainWindow::setupPython()
{
  this->Internal->PythonManager = new ddPythonManager(this);
  this->Internal->PythonManager->addObjectToPythonMain("_mainWindow", this);
  this->Internal->PythonManager->setupConsole(this);
  this->connect(this->Internal->ActionPythonConsole, SIGNAL(triggered()), this->Internal->PythonManager, SLOT(showConsole()));
}
