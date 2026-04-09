#requires -Version 5.1
# ============================================================================
# GlazeWM Konfig — XAML-based Configuration Tool
# ============================================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# --- Module Check ---
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    $result = [System.Windows.MessageBox]::Show(
        "The 'powershell-yaml' module is required.`nInstall it now?",
        "GlazeWM Konfig", "YesNo", "Question"
    )
    if ($result -eq 'Yes') {
        Install-Module -Name powershell-yaml -Scope CurrentUser -Force
    } else { exit }
}
Import-Module powershell-yaml

# --- Data Classes ---
Add-Type @"
public class KeybindingItem {
    public string Commands { get; set; }
    public string Bindings { get; set; }
}
public class WindowRuleItem {
    public string Commands { get; set; }
    public string MatchProcess { get; set; }
    public string MatchTitle { get; set; }
    public string MatchClass { get; set; }
}
"@

# --- State ---
$script:ConfigPath = Join-Path $env:USERPROFILE ".glzr\glazewm\config.yaml"
$script:KeybindingsList = New-Object 'System.Collections.ObjectModel.ObservableCollection[KeybindingItem]'
$script:WindowRulesList = New-Object 'System.Collections.ObjectModel.ObservableCollection[WindowRuleItem]'

# --- XAML ---
$xamlString = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="GlazeWM Konfig" Width="980" Height="740"
    Background="#1e1e2e" WindowStartupLocation="CenterScreen"
    FontFamily="Segoe UI" FontSize="13">
  <Window.Resources>
    <!-- Color Brushes -->
    <SolidColorBrush x:Key="BgBase" Color="#1e1e2e"/>
    <SolidColorBrush x:Key="BgMantle" Color="#181825"/>
    <SolidColorBrush x:Key="BgSurface0" Color="#313244"/>
    <SolidColorBrush x:Key="BgSurface1" Color="#45475a"/>
    <SolidColorBrush x:Key="BgSurface2" Color="#585b70"/>
    <SolidColorBrush x:Key="FgText" Color="#cdd6f4"/>
    <SolidColorBrush x:Key="FgSub" Color="#a6adc8"/>
    <SolidColorBrush x:Key="FgOverlay" Color="#6c7086"/>
    <SolidColorBrush x:Key="AccBlue" Color="#89b4fa"/>
    <SolidColorBrush x:Key="AccGreen" Color="#a6e3a1"/>
    <SolidColorBrush x:Key="AccRed" Color="#f38ba8"/>
    <SolidColorBrush x:Key="AccPeach" Color="#fab387"/>

    <!-- Toggle Switch -->
    <Style x:Key="ToggleSwitch" TargetType="{x:Type CheckBox}">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type CheckBox}">
            <StackPanel Orientation="Horizontal">
              <Border x:Name="bg" Width="44" Height="22" CornerRadius="11" Background="#585b70">
                <Ellipse x:Name="dot" Width="16" Height="16" Fill="#cdd6f4" HorizontalAlignment="Left" Margin="3,0,0,0"/>
              </Border>
              <ContentPresenter Margin="8,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="bg" Property="Background" Value="#89b4fa"/>
                <Setter TargetName="dot" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="dot" Property="Margin" Value="0,0,3,0"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- TextBox -->
    <Style TargetType="{x:Type TextBox}">
      <Setter Property="Background" Value="#45475a"/>
      <Setter Property="Foreground" Value="#cdd6f4"/>
      <Setter Property="BorderBrush" Value="#585b70"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="6,4"/>
      <Setter Property="CaretBrush" Value="#cdd6f4"/>
      <Style.Triggers>
        <Trigger Property="IsFocused" Value="True">
          <Setter Property="BorderBrush" Value="#89b4fa"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <!-- Button Accent -->
    <Style x:Key="BtnAccent" TargetType="{x:Type Button}">
      <Setter Property="Background" Value="#89b4fa"/>
      <Setter Property="Foreground" Value="#1e1e2e"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Padding" Value="16,6"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type Button}">
            <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#b4befe"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Button Secondary -->
    <Style x:Key="BtnSec" TargetType="{x:Type Button}">
      <Setter Property="Background" Value="#45475a"/>
      <Setter Property="Foreground" Value="#cdd6f4"/>
      <Setter Property="Padding" Value="12,6"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type Button}">
            <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#585b70"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- TabItem -->
    <Style TargetType="{x:Type TabItem}">
      <Setter Property="Foreground" Value="#a6adc8"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type TabItem}">
            <Border x:Name="bd" Padding="14,8" Margin="2,0" CornerRadius="6,6,0,0" Background="Transparent">
              <ContentPresenter ContentSource="Header"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#313244"/>
                <Setter Property="Foreground" Value="#89b4fa"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#45475a"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- ComboBox -->
    <ControlTemplate x:Key="ComboBoxToggleButton" TargetType="{x:Type ToggleButton}">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition />
          <ColumnDefinition Width="24" />
        </Grid.ColumnDefinitions>
        <Border x:Name="Border" Grid.ColumnSpan="2" CornerRadius="4" Background="#45475a" BorderBrush="#585b70" BorderThickness="1" />
        <Path x:Name="Arrow" Grid.Column="1" Fill="#cdd6f4" HorizontalAlignment="Center" VerticalAlignment="Center" Data="M0,0 L0,2 L4,6 L8,2 L8,0 L4,4 z" />
      </Grid>
      <ControlTemplate.Triggers>
        <Trigger Property="IsMouseOver" Value="true">
          <Setter TargetName="Border" Property="Background" Value="#585b70" />
        </Trigger>
        <Trigger Property="IsChecked" Value="true">
          <Setter TargetName="Border" Property="Background" Value="#585b70" />
        </Trigger>
      </ControlTemplate.Triggers>
    </ControlTemplate>

    <ControlTemplate x:Key="ComboBoxTemplate" TargetType="{x:Type ComboBox}">
      <Grid>
        <ToggleButton Name="ToggleButton" Template="{StaticResource ComboBoxToggleButton}" Grid.Column="2" Focusable="false" IsChecked="{Binding Path=IsDropDownOpen,Mode=TwoWay,RelativeSource={RelativeSource TemplatedParent}}" ClickMode="Press" />
        <ContentPresenter Name="ContentSite" IsHitTestVisible="False" Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}" ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}" Margin="8,4,24,4" VerticalAlignment="Center" HorizontalAlignment="Left" />
        <TextBox x:Name="PART_EditableTextBox" Style="{x:Null}" Template="{x:Null}" HorizontalAlignment="Left" VerticalAlignment="Center" Margin="8,4,24,4" Focusable="True" Background="Transparent" Foreground="#cdd6f4" Visibility="Hidden" IsReadOnly="{TemplateBinding IsReadOnly}"/>
        <Popup Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
          <Grid Name="DropDown" SnapsToDevicePixels="True" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="{TemplateBinding MaxDropDownHeight}">
            <Border x:Name="DropDownBorder" Background="#313244" BorderThickness="1" BorderBrush="#585b70" CornerRadius="4" Margin="0,2,0,0"/>
            <ScrollViewer Margin="0,4,0,4" SnapsToDevicePixels="True">
              <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained" />
            </ScrollViewer>
          </Grid>
        </Popup>
      </Grid>
      <ControlTemplate.Triggers>
        <Trigger Property="HasItems" Value="false">
          <Setter TargetName="DropDownBorder" Property="MinHeight" Value="95"/>
        </Trigger>
        <Trigger Property="IsEnabled" Value="false">
          <Setter Property="Foreground" Value="#6c7086"/>
        </Trigger>
      </ControlTemplate.Triggers>
    </ControlTemplate>

    <Style TargetType="{x:Type ComboBox}">
      <Setter Property="Foreground" Value="#cdd6f4" />
      <Setter Property="Template" Value="{StaticResource ComboBoxTemplate}" />
      <Setter Property="Cursor" Value="Hand" />
    </Style>

    <Style TargetType="{x:Type ComboBoxItem}">
      <Setter Property="Foreground" Value="#cdd6f4" />
      <Setter Property="Background" Value="Transparent" />
      <Setter Property="Padding" Value="10,6" />
      <Setter Property="Cursor" Value="Hand" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type ComboBoxItem}">
            <Border Name="Border" Padding="{TemplateBinding Padding}" Background="{TemplateBinding Background}" CornerRadius="2" Margin="4,0">
              <ContentPresenter />
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="true">
                <Setter TargetName="Border" Property="Background" Value="#45475a" />
              </Trigger>
              <Trigger Property="IsSelected" Value="true">
                <Setter TargetName="Border" Property="Background" Value="#89b4fa" />
                <Setter Property="Foreground" Value="#1e1e2e" />
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- DataGrid -->
    <Style TargetType="{x:Type DataGrid}">
      <Setter Property="Background" Value="#313244"/>
      <Setter Property="Foreground" Value="#cdd6f4"/>
      <Setter Property="BorderBrush" Value="#585b70"/>
      <Setter Property="RowBackground" Value="#313244"/>
      <Setter Property="AlternatingRowBackground" Value="#1e1e2e"/>
      <Setter Property="GridLinesVisibility" Value="Horizontal"/>
      <Setter Property="HorizontalGridLinesBrush" Value="#45475a"/>
      <Setter Property="HeadersVisibility" Value="Column"/>
    </Style>
    <Style TargetType="{x:Type DataGridColumnHeader}">
      <Setter Property="Background" Value="#181825"/>
      <Setter Property="Foreground" Value="#89b4fa"/>
      <Setter Property="Padding" Value="8,6"/>
      <Setter Property="BorderBrush" Value="#45475a"/>
      <Setter Property="BorderThickness" Value="0,0,1,1"/>
    </Style>
    <Style TargetType="{x:Type DataGridRow}">
      <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#45475a"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <Style TargetType="{x:Type DataGridCell}">
      <Setter Property="BorderBrush" Value="Transparent"/>
      <Setter Property="Foreground" Value="#cdd6f4"/>
      <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#45475a"/>
          <Setter Property="Foreground" Value="#cdd6f4"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <!-- ListBox -->
    <Style TargetType="{x:Type ListBox}">
      <Setter Property="Background" Value="#313244"/>
      <Setter Property="Foreground" Value="#cdd6f4"/>
      <Setter Property="BorderBrush" Value="#585b70"/>
    </Style>
    <Style TargetType="{x:Type ListBoxItem}">
      <Setter Property="Foreground" Value="#cdd6f4"/>
      <Setter Property="Padding" Value="8,6"/>
      <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#45475a"/>
        </Trigger>
      </Style.Triggers>
    </Style>
  </Window.Resources>

  <DockPanel>
    <!-- ===== TITLE BAR ===== -->
    <Border DockPanel.Dock="Top" Background="#181825" Padding="16,10">
      <StackPanel Orientation="Horizontal">
        <TextBlock Text="GlazeWM Konfig" FontSize="18" FontWeight="Bold" Foreground="#cdd6f4" VerticalAlignment="Center"/>
        <TextBlock Text="Configuration Tool" FontSize="12" Foreground="#6c7086" VerticalAlignment="Center" Margin="12,2,0,0"/>
      </StackPanel>
    </Border>

    <!-- ===== STATUS BAR ===== -->
    <Border DockPanel.Dock="Bottom" Background="#181825" Padding="12,8">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock Text="File:" VerticalAlignment="Center" Margin="0,0,6,0" Foreground="#a6adc8"/>
        <TextBox Grid.Column="1" x:Name="txtConfigPath" IsReadOnly="True" Background="#313244" FontSize="11" VerticalAlignment="Center"/>
        <Button Grid.Column="2" x:Name="btnBrowse" Content="Browse" Style="{StaticResource BtnSec}" Margin="8,0,0,0"/>
        <Button Grid.Column="3" x:Name="btnReload" Content="Reload" Style="{StaticResource BtnSec}" Margin="8,0,0,0"/>
        <Button Grid.Column="4" x:Name="btnSave" Content="Save" Style="{StaticResource BtnSec}" Margin="8,0,0,0"/>
        <Button Grid.Column="5" x:Name="btnSaveReload" Content="Save and Reload" Style="{StaticResource BtnAccent}" Margin="8,0,0,0"/>
      </Grid>
    </Border>

    <!-- ===== TAB CONTROL ===== -->
    <TabControl Background="#1e1e2e" BorderBrush="#313244" Margin="0" Padding="0">

      <!-- ==================== GENERAL ==================== -->
      <TabItem Header="General">
        <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="8">
          <StackPanel>
            <!-- Commands -->
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="Commands" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                <TextBlock Text="Startup Commands" Foreground="#cdd6f4" Margin="0,0,0,4"/>
                <TextBlock Text="Run when GlazeWM starts (e.g. shell-exec zebar)" FontSize="11" Foreground="#6c7086" Margin="0,0,0,4"/>
                <TextBox x:Name="txtStartupCmds" Height="40" AcceptsReturn="True" VerticalScrollBarVisibility="Auto"/>
                <TextBlock Text="Shutdown Commands" Foreground="#cdd6f4" Margin="0,10,0,4"/>
                <TextBox x:Name="txtShutdownCmds" Height="40" AcceptsReturn="True" VerticalScrollBarVisibility="Auto"/>
                <TextBlock Text="Config Reload Commands" Foreground="#cdd6f4" Margin="0,10,0,4"/>
                <TextBox x:Name="txtReloadCmds" Height="40" AcceptsReturn="True" VerticalScrollBarVisibility="Auto"/>
              </StackPanel>
            </Border>
            <!-- Focus & Cursor -->
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="Focus &amp; Cursor" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Focus follows cursor" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkFocusFollows" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Toggle workspace on refocus" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkToggleWS" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Cursor jump enabled" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkCursorJump" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Cursor jump trigger" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <ComboBox Grid.Column="1" x:Name="cboCursorTrigger" Width="180" HorizontalAlignment="Left">
                    <ComboBoxItem Content="monitor_focus"/>
                    <ComboBoxItem Content="window_focus"/>
                  </ComboBox>
                </Grid>
              </StackPanel>
            </Border>
            <!-- Display -->
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="Display" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Hide method" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <ComboBox Grid.Column="1" x:Name="cboHideMethod" Width="180" HorizontalAlignment="Left">
                    <ComboBoxItem Content="cloak"/>
                    <ComboBoxItem Content="hide"/>
                  </ComboBox>
                </Grid>
                <TextBlock Text="'cloak' recommended — hides windows with no animation" FontSize="11" Foreground="#6c7086" Margin="220,0,0,4"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Show all in taskbar" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkShowTaskbar" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
              </StackPanel>
            </Border>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- ==================== GAPS ==================== -->
      <TabItem Header="Gaps">
        <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="8">
          <StackPanel>
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="DPI Scaling" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Scale gaps with DPI" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkScaleDpi" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
              </StackPanel>
            </Border>
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="Inner Gap" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                <TextBlock Text="Gap between adjacent windows" FontSize="11" Foreground="#6c7086" Margin="0,0,0,6"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Inner gap" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <TextBox Grid.Column="1" x:Name="txtInnerGap" Width="120" HorizontalAlignment="Left"/>
                </Grid>
              </StackPanel>
            </Border>
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="Outer Gap" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                <TextBlock Text="Gap between windows and screen edge" FontSize="11" Foreground="#6c7086" Margin="0,0,0,6"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Top" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <TextBox Grid.Column="1" x:Name="txtOuterTop" Width="120" HorizontalAlignment="Left"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Right" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <TextBox Grid.Column="1" x:Name="txtOuterRight" Width="120" HorizontalAlignment="Left"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Bottom" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <TextBox Grid.Column="1" x:Name="txtOuterBottom" Width="120" HorizontalAlignment="Left"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Left" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <TextBox Grid.Column="1" x:Name="txtOuterLeft" Width="120" HorizontalAlignment="Left"/>
                </Grid>
              </StackPanel>
            </Border>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- ==================== WINDOW EFFECTS ==================== -->
      <TabItem Header="Effects">
        <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="8">
          <StackPanel>
            <!-- Focused Window -->
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="Focused Window" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Border enabled" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkFocBorder" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Border color" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <TextBox Grid.Column="1" x:Name="txtFocBorderColor" Width="100"/>
                  <Rectangle Grid.Column="2" x:Name="rectFocBorder" Width="22" Height="22" Margin="8,0,0,0" RadiusX="4" RadiusY="4" Fill="White" Stroke="#585b70"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Hide title bar" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkFocHideTitle" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Corner style enabled" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkFocCorner" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Corner style" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <ComboBox Grid.Column="1" x:Name="cboFocCorner" Width="160" HorizontalAlignment="Left">
                    <ComboBoxItem Content="square"/><ComboBoxItem Content="rounded"/><ComboBoxItem Content="small_rounded"/>
                  </ComboBox>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Transparency enabled" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkFocTransp" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Opacity" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <Slider Grid.Column="1" x:Name="sldFocOpacity" Width="200" Minimum="0" Maximum="100" Value="100" VerticalAlignment="Center"/>
                  <TextBlock Grid.Column="2" x:Name="lblFocOpacity" Text="100%" Foreground="#cdd6f4" Margin="8,0,0,0" VerticalAlignment="Center" Width="40"/>
                </Grid>
              </StackPanel>
            </Border>
            <!-- Other Windows -->
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="Other Windows" FontSize="15" FontWeight="SemiBold" Foreground="#fab387" Margin="0,0,0,10"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Border enabled" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkOthBorder" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Border color" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <TextBox Grid.Column="1" x:Name="txtOthBorderColor" Width="100"/>
                  <Rectangle Grid.Column="2" x:Name="rectOthBorder" Width="22" Height="22" Margin="8,0,0,0" RadiusX="4" RadiusY="4" Fill="Gray" Stroke="#585b70"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Hide title bar" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkOthHideTitle" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Corner style enabled" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkOthCorner" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Corner style" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <ComboBox Grid.Column="1" x:Name="cboOthCorner" Width="160" HorizontalAlignment="Left">
                    <ComboBoxItem Content="square"/><ComboBoxItem Content="rounded"/><ComboBoxItem Content="small_rounded"/>
                  </ComboBox>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Transparency enabled" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkOthTransp" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Opacity" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <Slider Grid.Column="1" x:Name="sldOthOpacity" Width="200" Minimum="0" Maximum="100" Value="100" VerticalAlignment="Center"/>
                  <TextBlock Grid.Column="2" x:Name="lblOthOpacity" Text="100%" Foreground="#cdd6f4" Margin="8,0,0,0" VerticalAlignment="Center" Width="40"/>
                </Grid>
              </StackPanel>
            </Border>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- ==================== BEHAVIOR ==================== -->
      <TabItem Header="Behavior">
        <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="8">
          <StackPanel>
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="Initial State" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="New window state" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <ComboBox Grid.Column="1" x:Name="cboInitialState" Width="160" HorizontalAlignment="Left">
                    <ComboBoxItem Content="tiling"/><ComboBoxItem Content="floating"/>
                  </ComboBox>
                </Grid>
              </StackPanel>
            </Border>
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="Floating Defaults" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Centered" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkFloatCenter" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Shown on top" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkFloatOnTop" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
              </StackPanel>
            </Border>
            <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
              <StackPanel>
                <TextBlock Text="Fullscreen Defaults" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Maximized" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkFullMax" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
                <Grid Margin="0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="Shown on top" VerticalAlignment="Center" Foreground="#cdd6f4"/>
                  <CheckBox Grid.Column="1" x:Name="chkFullOnTop" Style="{StaticResource ToggleSwitch}"/>
                </Grid>
              </StackPanel>
            </Border>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- ==================== WORKSPACES ==================== -->
      <TabItem Header="Workspaces">
        <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
          <DockPanel>
            <TextBlock DockPanel.Dock="Top" Text="Workspaces" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
            <StackPanel DockPanel.Dock="Bottom" Orientation="Horizontal" Margin="0,10,0,0">
              <TextBox x:Name="txtNewWS" Width="200" Margin="0,0,8,0"/>
              <Button x:Name="btnAddWS" Content="+ Add" Style="{StaticResource BtnAccent}" Margin="0,0,8,0"/>
              <Button x:Name="btnRemoveWS" Content="− Remove" Style="{StaticResource BtnSec}"/>
            </StackPanel>
            <ListBox x:Name="lstWorkspaces" Margin="0,0,0,0"/>
          </DockPanel>
        </Border>
      </TabItem>

      <!-- ==================== WINDOW RULES ==================== -->
      <TabItem Header="Rules">
        <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
          <DockPanel>
            <TextBlock DockPanel.Dock="Top" Text="Window Rules" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
            <StackPanel DockPanel.Dock="Bottom" Orientation="Horizontal" Margin="0,10,0,0">
              <Button x:Name="btnAddRule" Content="+ Add Rule" Style="{StaticResource BtnAccent}" Margin="0,0,8,0"/>
              <Button x:Name="btnRemoveRule" Content="− Remove" Style="{StaticResource BtnSec}"/>
            </StackPanel>
            <DataGrid x:Name="dgRules" AutoGenerateColumns="False" CanUserAddRows="False" CanUserDeleteRows="False" SelectionMode="Single">
              <DataGrid.Columns>
                <DataGridTextColumn Header="Command" Binding="{Binding Commands}" Width="120"/>
                <DataGridTextColumn Header="Match Process" Binding="{Binding MatchProcess}" Width="*"/>
                <DataGridTextColumn Header="Match Title" Binding="{Binding MatchTitle}" Width="*"/>
                <DataGridTextColumn Header="Match Class" Binding="{Binding MatchClass}" Width="*"/>
              </DataGrid.Columns>
            </DataGrid>
          </DockPanel>
        </Border>
      </TabItem>

      <!-- ==================== KEYBINDINGS ==================== -->
      <TabItem Header="Keys">
        <Border Background="#313244" CornerRadius="8" Padding="16" Margin="8">
          <DockPanel>
            <TextBlock DockPanel.Dock="Top" Text="Keybindings" FontSize="15" FontWeight="SemiBold" Foreground="#89b4fa" Margin="0,0,0,10"/>
            <StackPanel DockPanel.Dock="Bottom" Orientation="Horizontal" Margin="0,10,0,0">
              <Button x:Name="btnAddKey" Content="+ Add Keybinding" Style="{StaticResource BtnAccent}" Margin="0,0,8,0"/>
              <Button x:Name="btnRemoveKey" Content="− Remove" Style="{StaticResource BtnSec}"/>
            </StackPanel>
            <DataGrid x:Name="dgKeys" AutoGenerateColumns="False" CanUserAddRows="False" CanUserDeleteRows="False" SelectionMode="Single">
              <DataGrid.Columns>
                <DataGridTextColumn Header="Command(s)" Binding="{Binding Commands}" Width="*"/>
                <DataGridTextColumn Header="Binding(s)" Binding="{Binding Bindings}" Width="*"/>
              </DataGrid.Columns>
            </DataGrid>
          </DockPanel>
        </Border>
      </TabItem>

    </TabControl>
  </DockPanel>
</Window>
'@

# --- Parse XAML ---
$xamlString = $xamlString -replace 'x:Name=', 'Name='
[xml]$xaml = $xamlString
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# --- Find Controls ---
$controls = @{}
$names = @(
    'txtConfigPath','btnBrowse','btnReload','btnSave','btnSaveReload',
    'txtStartupCmds','txtShutdownCmds','txtReloadCmds',
    'chkFocusFollows','chkToggleWS','chkCursorJump','cboCursorTrigger',
    'cboHideMethod','chkShowTaskbar',
    'chkScaleDpi','txtInnerGap','txtOuterTop','txtOuterRight','txtOuterBottom','txtOuterLeft',
    'chkFocBorder','txtFocBorderColor','rectFocBorder','chkFocHideTitle',
    'chkFocCorner','cboFocCorner','chkFocTransp','sldFocOpacity','lblFocOpacity',
    'chkOthBorder','txtOthBorderColor','rectOthBorder','chkOthHideTitle',
    'chkOthCorner','cboOthCorner','chkOthTransp','sldOthOpacity','lblOthOpacity',
    'cboInitialState','chkFloatCenter','chkFloatOnTop','chkFullMax','chkFullOnTop',
    'lstWorkspaces','txtNewWS','btnAddWS','btnRemoveWS',
    'dgRules','btnAddRule','btnRemoveRule',
    'dgKeys','btnAddKey','btnRemoveKey'
)
foreach ($n in $names) { $controls[$n] = $window.FindName($n) }

# --- Helpers ---
function Set-ComboValue($combo, [string]$value) {
    for ($i = 0; $i -lt $combo.Items.Count; $i++) {
        if ($combo.Items[$i].Content -eq $value) {
            $combo.SelectedIndex = $i; return
        }
    }
}
function Get-ComboValue($combo) {
    if ($combo.SelectedItem) { return $combo.SelectedItem.Content }
    return ""
}
function Parse-CommandList([string]$text) {
    if ([string]::IsNullOrWhiteSpace($text)) { return @() }
    return @($text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
}
function Format-CommandList($arr) {
    if (-not $arr -or $arr.Count -eq 0) { return "" }
    return ($arr -join "`n")
}
function Try-ParseColor([string]$hex) {
    try {
        $c = [System.Windows.Media.ColorConverter]::ConvertFromString($hex)
        return [System.Windows.Media.SolidColorBrush]::new($c)
    } catch { return $null }
}

# --- Load Config ---
function Load-Config([string]$path) {
    if (-not (Test-Path $path)) {
        [System.Windows.MessageBox]::Show("Config file not found:`n$path", "Error", "OK", "Error")
        return
    }
    $script:ConfigPath = $path
    $controls['txtConfigPath'].Text = $path
    $yaml = Get-Content $path -Raw | ConvertFrom-Yaml

    # General
    $g = $yaml['general']
    if ($g) {
        $controls['chkFocusFollows'].IsChecked = [bool]$g['focus_follows_cursor']
        $controls['chkToggleWS'].IsChecked = [bool]$g['toggle_workspace_on_refocus']
        if ($g['cursor_jump']) {
            $controls['chkCursorJump'].IsChecked = [bool]$g['cursor_jump']['enabled']
            Set-ComboValue $controls['cboCursorTrigger'] $g['cursor_jump']['trigger']
        }
        Set-ComboValue $controls['cboHideMethod'] $g['hide_method']
        $controls['chkShowTaskbar'].IsChecked = [bool]$g['show_all_in_taskbar']
        $controls['txtStartupCmds'].Text = Format-CommandList $g['startup_commands']
        $controls['txtShutdownCmds'].Text = Format-CommandList $g['shutdown_commands']
        $controls['txtReloadCmds'].Text = Format-CommandList $g['config_reload_commands']
    }

    # Gaps
    $gp = $yaml['gaps']
    if ($gp) {
        $controls['chkScaleDpi'].IsChecked = [bool]$gp['scale_with_dpi']
        $controls['txtInnerGap'].Text = "$($gp['inner_gap'])"
        if ($gp['outer_gap']) {
            $controls['txtOuterTop'].Text = "$($gp['outer_gap']['top'])"
            $controls['txtOuterRight'].Text = "$($gp['outer_gap']['right'])"
            $controls['txtOuterBottom'].Text = "$($gp['outer_gap']['bottom'])"
            $controls['txtOuterLeft'].Text = "$($gp['outer_gap']['left'])"
        }
    }

    # Window Effects - helper
    function Load-WindowEffects($prefix, $data) {
        if (-not $data) { return }
        if ($data['border']) {
            $controls["chk${prefix}Border"].IsChecked = [bool]$data['border']['enabled']
            $controls["txt${prefix}BorderColor"].Text = "$($data['border']['color'])"
            $brush = Try-ParseColor "$($data['border']['color'])"
            if ($brush) { $controls["rect${prefix}Border"].Fill = $brush }
        }
        if ($data['hide_title_bar']) {
            $controls["chk${prefix}HideTitle"].IsChecked = [bool]$data['hide_title_bar']['enabled']
        }
        if ($data['corner_style']) {
            $controls["chk${prefix}Corner"].IsChecked = [bool]$data['corner_style']['enabled']
            Set-ComboValue $controls["cbo${prefix}Corner"] $data['corner_style']['style']
        }
        if ($data['transparency']) {
            $controls["chk${prefix}Transp"].IsChecked = [bool]$data['transparency']['enabled']
            $op = "$($data['transparency']['opacity'])" -replace '%',''
            try { $controls["sld${prefix}Opacity"].Value = [double]$op } catch {}
            $controls["lbl${prefix}Opacity"].Text = "${op}%"
        }
    }

    $we = $yaml['window_effects']
    if ($we) {
        Load-WindowEffects 'Foc' $we['focused_window']
        Load-WindowEffects 'Oth' $we['other_windows']
    }

    # Window Behavior
    $wb = $yaml['window_behavior']
    if ($wb) {
        Set-ComboValue $controls['cboInitialState'] $wb['initial_state']
        if ($wb['state_defaults']) {
            $fl = $wb['state_defaults']['floating']
            if ($fl) {
                $controls['chkFloatCenter'].IsChecked = [bool]$fl['centered']
                $controls['chkFloatOnTop'].IsChecked = [bool]$fl['shown_on_top']
            }
            $fs = $wb['state_defaults']['fullscreen']
            if ($fs) {
                $controls['chkFullMax'].IsChecked = [bool]$fs['maximized']
                $controls['chkFullOnTop'].IsChecked = [bool]$fs['shown_on_top']
            }
        }
    }

    # Workspaces
    $controls['lstWorkspaces'].Items.Clear()
    if ($yaml['workspaces']) {
        foreach ($ws in $yaml['workspaces']) {
            $controls['lstWorkspaces'].Items.Add($ws['name']) | Out-Null
        }
    }

    # Window Rules
    $script:WindowRulesList.Clear()
    if ($yaml['window_rules']) {
        foreach ($rule in $yaml['window_rules']) {
            $cmds = ($rule['commands'] -join ', ')
            if ($rule['match']) {
                foreach ($m in $rule['match']) {
                    $item = New-Object WindowRuleItem
                    $item.Commands = $cmds
                    foreach ($key in $m.Keys) {
                        $val = $m[$key]
                        $opStr = ""
                        if ($val -is [hashtable] -or $val -is [System.Collections.Specialized.OrderedDictionary]) {
                            foreach ($op in $val.Keys) { $opStr = "${op}:$($val[$op])" }
                        } else { $opStr = "equals:$val" }
                        switch ($key) {
                            'window_process' { $item.MatchProcess = $opStr }
                            'window_title'   { $item.MatchTitle = $opStr }
                            'window_class'   { $item.MatchClass = $opStr }
                        }
                    }
                    $script:WindowRulesList.Add($item)
                }
            }
        }
    }
    $controls['dgRules'].ItemsSource = $script:WindowRulesList

    # Keybindings
    $script:KeybindingsList.Clear()
    if ($yaml['keybindings']) {
        foreach ($kb in $yaml['keybindings']) {
            $item = New-Object KeybindingItem
            $item.Commands = ($kb['commands'] -join ', ')
            $item.Bindings = ($kb['bindings'] -join ', ')
            $script:KeybindingsList.Add($item)
        }
    }
    $controls['dgKeys'].ItemsSource = $script:KeybindingsList
}

# --- Save Config ---
function Save-Config([string]$path) {
    $config = [ordered]@{}

    # General
    $config['general'] = [ordered]@{
        startup_commands = Parse-CommandList $controls['txtStartupCmds'].Text
        shutdown_commands = Parse-CommandList $controls['txtShutdownCmds'].Text
        config_reload_commands = Parse-CommandList $controls['txtReloadCmds'].Text
        focus_follows_cursor = [bool]$controls['chkFocusFollows'].IsChecked
        toggle_workspace_on_refocus = [bool]$controls['chkToggleWS'].IsChecked
        cursor_jump = [ordered]@{
            enabled = [bool]$controls['chkCursorJump'].IsChecked
            trigger = Get-ComboValue $controls['cboCursorTrigger']
        }
        hide_method = Get-ComboValue $controls['cboHideMethod']
        show_all_in_taskbar = [bool]$controls['chkShowTaskbar'].IsChecked
    }

    # Gaps
    $config['gaps'] = [ordered]@{
        scale_with_dpi = [bool]$controls['chkScaleDpi'].IsChecked
        inner_gap = $controls['txtInnerGap'].Text
        outer_gap = [ordered]@{
            top = $controls['txtOuterTop'].Text
            right = $controls['txtOuterRight'].Text
            bottom = $controls['txtOuterBottom'].Text
            left = $controls['txtOuterLeft'].Text
        }
    }

    # Window Effects helper
    function Build-WindowEffects($prefix) {
        return [ordered]@{
            border = [ordered]@{
                enabled = [bool]$controls["chk${prefix}Border"].IsChecked
                color = $controls["txt${prefix}BorderColor"].Text
            }
            hide_title_bar = [ordered]@{
                enabled = [bool]$controls["chk${prefix}HideTitle"].IsChecked
            }
            corner_style = [ordered]@{
                enabled = [bool]$controls["chk${prefix}Corner"].IsChecked
                style = Get-ComboValue $controls["cbo${prefix}Corner"]
            }
            transparency = [ordered]@{
                enabled = [bool]$controls["chk${prefix}Transp"].IsChecked
                opacity = "$([int]$controls["sld${prefix}Opacity"].Value)%"
            }
        }
    }

    $config['window_effects'] = [ordered]@{
        focused_window = Build-WindowEffects 'Foc'
        other_windows = Build-WindowEffects 'Oth'
    }

    # Window Behavior
    $config['window_behavior'] = [ordered]@{
        initial_state = Get-ComboValue $controls['cboInitialState']
        state_defaults = [ordered]@{
            floating = [ordered]@{
                centered = [bool]$controls['chkFloatCenter'].IsChecked
                shown_on_top = [bool]$controls['chkFloatOnTop'].IsChecked
            }
            fullscreen = [ordered]@{
                maximized = [bool]$controls['chkFullMax'].IsChecked
                shown_on_top = [bool]$controls['chkFullOnTop'].IsChecked
            }
        }
    }

    # Workspaces
    $config['workspaces'] = @()
    foreach ($ws in $controls['lstWorkspaces'].Items) {
        $config['workspaces'] += [ordered]@{ name = "$ws" }
    }

    # Window Rules
    $config['window_rules'] = @()
    $ruleGroups = @{}
    foreach ($r in $script:WindowRulesList) {
        $key = $r.Commands
        if (-not $ruleGroups.ContainsKey($key)) { $ruleGroups[$key] = @() }
        $match = [ordered]@{}
        if ($r.MatchProcess) {
            $parts = $r.MatchProcess -split ':', 2
            $match['window_process'] = [ordered]@{ $parts[0] = $parts[1] }
        }
        if ($r.MatchTitle) {
            $parts = $r.MatchTitle -split ':', 2
            $match['window_title'] = [ordered]@{ $parts[0] = $parts[1] }
        }
        if ($r.MatchClass) {
            $parts = $r.MatchClass -split ':', 2
            $match['window_class'] = [ordered]@{ $parts[0] = $parts[1] }
        }
        $ruleGroups[$key] += $match
    }
    foreach ($cmdKey in $ruleGroups.Keys) {
        $cmds = @($cmdKey -split ',\s*')
        $config['window_rules'] += [ordered]@{
            commands = $cmds
            match = $ruleGroups[$cmdKey]
        }
    }

    # Keybindings
    $config['keybindings'] = @()
    foreach ($kb in $script:KeybindingsList) {
        $cmds = @($kb.Commands -split ',\s*')
        $binds = @($kb.Bindings -split ',\s*')
        $config['keybindings'] += [ordered]@{
            commands = $cmds
            bindings = $binds
        }
    }

    # Binding modes (preserve from original if exists)
    if ($script:OriginalConfig -and $script:OriginalConfig['binding_modes']) {
        $config['binding_modes'] = $script:OriginalConfig['binding_modes']
    }

    $yamlOut = ConvertTo-Yaml $config
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, "$yamlOut`n", $utf8NoBom)
    [System.Windows.MessageBox]::Show("Config saved to:`n$path", "GlazeWM Konfig", "OK", "Information")
}

# --- Event Handlers ---

# Browse
$controls['btnBrowse'].Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "YAML files (*.yaml;*.yml)|*.yaml;*.yml|All files (*.*)|*.*"
    $dlg.InitialDirectory = Split-Path $script:ConfigPath
    if ($dlg.ShowDialog()) {
        Load-Config $dlg.FileName
    }
})

# Save
$controls['btnSave'].Add_Click({
    $path = $controls['txtConfigPath'].Text
    if ([string]::IsNullOrWhiteSpace($path)) {
        $dlg = New-Object Microsoft.Win32.SaveFileDialog
        $dlg.Filter = "YAML files (*.yaml)|*.yaml"
        $dlg.FileName = "config.yaml"
        if ($dlg.ShowDialog()) { $path = $dlg.FileName }
        else { return }
    }
    Save-Config $path
})

# Reload
$controls['btnReload'].Add_Click({
    $wshell = New-Object -ComObject wscript.shell
    $wshell.SendKeys("+%r")
})

# Save and Reload
$controls['btnSaveReload'].Add_Click({
    $path = $controls['txtConfigPath'].Text
    if ([string]::IsNullOrWhiteSpace($path)) {
        $dlg = New-Object Microsoft.Win32.SaveFileDialog
        $dlg.Filter = "YAML files (*.yaml)|*.yaml"
        $dlg.FileName = "config.yaml"
        if ($dlg.ShowDialog()) { $path = $dlg.FileName }
        else { return }
    }
    Save-Config $path

    # Only send reload keys if config saving was not cancelled
    $wshell = New-Object -ComObject wscript.shell
    $wshell.SendKeys("+%r")
})

# Workspace Add/Remove
$controls['btnAddWS'].Add_Click({
    $name = $controls['txtNewWS'].Text.Trim()
    if ($name -ne '') {
        $controls['lstWorkspaces'].Items.Add($name) | Out-Null
        $controls['txtNewWS'].Text = ''
    }
})
$controls['btnRemoveWS'].Add_Click({
    $sel = $controls['lstWorkspaces'].SelectedIndex
    if ($sel -ge 0) { $controls['lstWorkspaces'].Items.RemoveAt($sel) }
})

# Rules Add/Remove
$controls['btnAddRule'].Add_Click({
    $item = New-Object WindowRuleItem
    $item.Commands = 'ignore'
    $item.MatchProcess = 'equals:'
    $script:WindowRulesList.Add($item)
})
$controls['btnRemoveRule'].Add_Click({
    $sel = $controls['dgRules'].SelectedIndex
    if ($sel -ge 0) { $script:WindowRulesList.RemoveAt($sel) }
})

# Keybinding Add/Remove
$controls['btnAddKey'].Add_Click({
    $item = New-Object KeybindingItem
    $item.Commands = ''
    $item.Bindings = ''
    $script:KeybindingsList.Add($item)
})
$controls['btnRemoveKey'].Add_Click({
    $sel = $controls['dgKeys'].SelectedIndex
    if ($sel -ge 0) { $script:KeybindingsList.RemoveAt($sel) }
})

# Color preview updates
$controls['txtFocBorderColor'].Add_TextChanged({
    $brush = Try-ParseColor $controls['txtFocBorderColor'].Text
    if ($brush) { $controls['rectFocBorder'].Fill = $brush }
})
$controls['txtOthBorderColor'].Add_TextChanged({
    $brush = Try-ParseColor $controls['txtOthBorderColor'].Text
    if ($brush) { $controls['rectOthBorder'].Fill = $brush }
})

# Opacity slider labels
$controls['sldFocOpacity'].Add_ValueChanged({
    $controls['lblFocOpacity'].Text = "$([int]$controls['sldFocOpacity'].Value)%"
})
$controls['sldOthOpacity'].Add_ValueChanged({
    $controls['lblOthOpacity'].Text = "$([int]$controls['sldOthOpacity'].Value)%"
})

# --- Initial Load ---
$controls['txtConfigPath'].Text = $script:ConfigPath
if (Test-Path $script:ConfigPath) {
    $script:OriginalConfig = Get-Content $script:ConfigPath -Raw | ConvertFrom-Yaml
    Load-Config $script:ConfigPath
} else {
    # Set defaults
    $controls['chkFocusFollows'].IsChecked = $true
    $controls['chkCursorJump'].IsChecked = $true
    Set-ComboValue $controls['cboCursorTrigger'] 'window_focus'
    Set-ComboValue $controls['cboHideMethod'] 'cloak'
    $controls['chkShowTaskbar'].IsChecked = $true
    $controls['chkScaleDpi'].IsChecked = $true
    $controls['txtInnerGap'].Text = '1px'
    $controls['txtOuterTop'].Text = '1px'
    $controls['txtOuterRight'].Text = '1px'
    $controls['txtOuterBottom'].Text = '1px'
    $controls['txtOuterLeft'].Text = '1px'
    Set-ComboValue $controls['cboInitialState'] 'tiling'
    1..9 | ForEach-Object { $controls['lstWorkspaces'].Items.Add("$_") | Out-Null }
}

# --- Show Window ---
$window.ShowDialog() | Out-Null
