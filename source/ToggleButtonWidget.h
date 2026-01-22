#pragma once

// Qt6 headers are directly in framework Headers, use framework-style includes
#include <QObject>
#include <QPushButton>
#include <QTabWidget>
#include <QGuiApplication>

// Include DDImage for CallbackReason enum (needed for MOC)
#include "DDImage/Knobs.h"

class ToggleButtonKnob;

class ToggleButtonWidget : public QPushButton
{
	Q_OBJECT

	ToggleButtonKnob* knob;
	bool& buttonState;

public:

	ToggleButtonWidget(const char*, bool&, ToggleButtonKnob*);
	~ToggleButtonWidget();
	static int WidgetCallback(void*, DD::Image::Knob::CallbackReason);

public Q_SLOTS:

	void buttonToggleCallback(bool);
};
