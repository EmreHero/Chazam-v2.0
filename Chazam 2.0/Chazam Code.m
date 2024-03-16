classdef Chazam_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        ChazamUIFigure                 matlab.ui.Figure
        Accuracy                       matlab.ui.control.Label
        AccuracyBorder                 matlab.ui.control.Label
        MachineLearningMethodDropDown  matlab.ui.control.DropDown
        MachineLearningMethodDropDownLabel  matlab.ui.control.Label
        PauseButton                    matlab.ui.control.Button
        StopButton                     matlab.ui.control.Button
        PlayButton                     matlab.ui.control.Button
        PresstoSelectaFileButton       matlab.ui.control.Button
        OtherSongs                     matlab.ui.control.Label
        OtherSongsBorder               matlab.ui.control.Label
        Genre                          matlab.ui.control.Label
        GenreBorder                    matlab.ui.control.Label
        StartButton                    matlab.ui.control.Button
        Label                          matlab.ui.control.Label
        Label_2                        matlab.ui.control.Label
        Image                          matlab.ui.control.Image
    end

    
    properties (Access = private)
        fullPath            % Selected Audio File
        canStart = false;   % For disabling start button after finishing the process
        player              % For playing the selected audio
        isPaused = true;    % If paused true, else false
        isPlaying = false;  % If audio is playing true, else false
        audioCanBePlayed = false;   % If the audio can be played true, else false

        % Songs to Suggest
        blues       = ["Memphis Blues - W.C. Handy","Pine Top Boogie - Pine Top Smith","Dust My Broom - Elmore James","Boogie Chillun - John Lee Hooker","Mannish Boy - Muddy Waters","Mannish Boy - Muddy Waters","Stormy Monday - T-Bone Walker","Spoonful - Willie Dixon","Born Under A Bad Sign - Albert King","Smokestack Lightnin' - Howlin' Wolf"];
        classical   = ["The Four Seasons (Le Quattro Stagioni)","Requiem in D Minor, K. 626",  "Symphony No. 9 in D Minor Op. 125", "Nocturnes","The Nutcracker","Op. 71, Für Elise (Bagatelle No. 25 in A minor)","WoO 59, Eine kleine Nachtmusik (Serenade No. 13 in G Major)","Gymnopédies","Boléro"];
        country     = ["Josh Turner-Why Don't We Just Dance","Taylor Swift-Ours","Taylor Swift-Mine","Tim McGraw-Felt Good on My Lips","Rascal Flatts-Why Wait","Darius Rucker-Comeback Song","Billy Currington-That's How Country Boys Roll","Justin Moore-Backwoods","Taylor Swift-Fearless","Lee Brice-Beautiful Every Time"];
        disco       = ["I Will Survive - Gloria Gaynor","Le Freak - Chic","Stayin' Alive - Bee Gees","Super Freak - Rick James","Funky Town - Lipps Inc.","Disco Inferno - Trammps","Y.M.C.A. - Village People","Born To Be Alive - Patrick Hernandez","Billie Jean - Michael Jackson","That's The Way I Like It - K.C. & the Sunshine Band"];
        hiphop      = ["Ur The Moon", "Cash, Open Scars","Love Me Enough","Beep Beep (Remix)","Dear Summer", "Roman's Revenge", "FACTS",  "Gimme Da Lite","Not My Fault"];
        
        % Models
        modelFineTree
        modelMediumTree
        modelCoarseTree
        modelLinearSVM
        modelQuadraticSVM
        modelFineKNN
        modelMediumKNN
        modelCoarseKNN
        modelBoostedTrees
        modelNarrowNeuralNetwork
        modelMediumNeuralNetwork
    end
    
    methods (Access = private)
        
        % For enabling and disabling the start button
        function StartButtonEnable(app, on)
            if on
                app.StartButton.Text = "Start";
                set(app.StartButton, 'Visible', 'on')
                set(app.StartButton, 'Enable', 'on')
            else
                set(app.StartButton, 'Visible', 'off')
                set(app.StartButton, 'Enable', 'off')
            end
        end
        
        % For reseting the player buttons to their inital state
        % invert should be false when playing, true when stopping
        function ResetPlayerButtons(app, invert)
            app.PauseButton.Text = "Pause";
            if invert
                set(app.PauseButton, 'Enable', 'on');
                set(app.PlayButton, 'Enable', 'off');
                set(app.StopButton, 'Enable', 'on');
            else
                set(app.PauseButton, 'Enable', 'off');
                set(app.PlayButton, 'Enable', 'on');
                set(app.StopButton, 'Enable', 'off');
            end
        end
        
        % For reseting the genre, suggestion and accuracy display to their inital state
        function ResetDisplay(app)
            app.Genre.Text = "Genre";
            app.OtherSongs.Text = "Our Suggestions";
            app.Accuracy.Text = "Accuracy";
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Loading trained model
            load ClassificationLearner.mat 'FineTree' 'MediumTree' 'CoarseTree' 'LinearSVM' 'QuadraticSVM' 'FineKNN' 'MediumKNN' 'CoarseKNN' 'BoostedTrees' 'NarrowNeuralNetwork' 'MediumNeuralNetwork';
            
            % Defining all models
            app.modelFineTree = FineTree;
            app.modelMediumTree = MediumTree;
            app.modelCoarseTree = CoarseTree;
            app.modelLinearSVM = LinearSVM;
            app.modelQuadraticSVM = QuadraticSVM;
            app.modelFineKNN = FineKNN;
            app.modelMediumKNN = MediumKNN;
            app.modelCoarseKNN = CoarseKNN;
            app.modelBoostedTrees = BoostedTrees;
            app.modelNarrowNeuralNetwork = NarrowNeuralNetwork;
            app.modelMediumNeuralNetwork = MediumNeuralNetwork;
        end

        % Button pushed function: PresstoSelectaFileButton
        function PresstoSelectaFileButtonPushed(app, event)
            % Reseting everything
            if app.audioCanBePlayed && app.isPlaying % to stop audio from playing
                stop(app.player);
            end
            app.PresstoSelectaFileButton.Text = "Press to Select a File";
            app.isPaused = true;
            app.isPlaying = false;
            app.canStart = false;
            app.audioCanBePlayed = false;
            StartButtonEnable(app, false)
            ResetPlayerButtons(app, false)
            ResetDisplay(app)

            % Selecting File
            [fileName, pathName, index] = uigetfile('*.wav');
            figure(app.ChazamUIFigure); % to prevent the window from getting minimized
            
            if index == 0 % if nothing selected
                return;
            end
            
            % Giving full path to a global variable in order to access it from another function
            app.fullPath = strcat(pathName,fileName);
            
            % Check if the extention is .wav
            [~,~,ext] = fileparts(app.fullPath);

            if ext ~= ".wav" % if the extention is not .wav

                % Pop up window to display the error
                ErrorBox = msgbox("Invalid File Type (Should be '.wav')","Error","error");
                
                figure(app.ChazamUIFigure); % to prevent the window from getting minimized
                figure(ErrorBox);

            else % if the extention is .wav

                % Cutting .wav from the file name to display only file's name
                fileNameWithoutWav = strrep(fileName,'.wav','');
    
                % Display Selected File's Name
                app.PresstoSelectaFileButton.Text = fileNameWithoutWav;
                
                % Allowing the program to be started
                StartButtonEnable(app, true)
                app.canStart = true;
                app.audioCanBePlayed = true;
            end
        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            if ~app.canStart % to prevent spamming the start button
                return;
            end
            
            % Reading audio file
            [y, ~] = audioread(app.fullPath);
            
            % Copied from the professor
            % Processes the signal to suitable format
            y1=abs(spectrogram(y,kaiser(2048,128),120,16,1E3,'yaxis'));
            y1=y1(:);
            audioTable=[]; % renamed from VeriSeti
            t=0;
            if length(y1)>=3087
                 y1=y1(1:3087);
            else
                t=1;
            end
            if t==0
                audioTable=[audioTable y1];
            end % until here
            
            % Getting the selected model
            modelStr = app.MachineLearningMethodDropDown.Value;

            % Selects the right model and accuracy value
            switch modelStr
                case "Fine Tree"
                    model = app.modelFineTree;
                    accuracy = "36.6";
                case "Medium Tree"
                    model = app.modelMediumTree;
                    accuracy = "38.8";
                case "Coarse Tree"
                    model = app.modelCoarseTree;
                    accuracy = "40.2";
                case "Linear SVM"
                    model = app.modelLinearSVM;
                    accuracy = "58.0";
                case "Quadratic SVM (Best Accuracy)"
                    model = app.modelQuadraticSVM;
                    accuracy = "59.8";
                case "Fine KNN"
                    model = app.modelFineKNN;
                    accuracy = "38.1";
                case "Medium KNN"
                    model = app.modelMediumKNN;
                    accuracy = "36.3";
                case "Coarse KNN"
                    model = app.modelCoarseKNN;
                    accuracy = "25.1";
                case "Boosted Trees"
                    model = app.modelBoostedTrees;
                    accuracy = "49.9";
                case "Narrow Neural Network"
                    model = app.modelNarrowNeuralNetwork;
                    accuracy = "53.5";
                case "Medium Neural Network"
                    model = app.modelMediumNeuralNetwork;
                    accuracy = "50.1";
            end

            % Pedicting genre
            pred = model.predictFcn(audioTable);
            
            % Converting numbers to genres and setting the suggestions array
            switch pred 
                case 1
                    genre = 'Blues';
                    suggestions = app.blues;
                case 2
                    genre = 'Classical';
                    suggestions = app.classical;
                case 3
                    genre = 'Country';
                    suggestions = app.country;
                case 4
                    genre = 'Disco';
                    suggestions = app.disco;
                case 5
                    genre = 'Hiphop';
                    suggestions = app.hiphop;
            end

            % Displaying genre
            genre = strcat("Genre: ", genre);
            app.Genre.Text = genre;

            % Displaying accuracy
            accuracy = strcat("Accuracy: %", accuracy);
            app.Accuracy.Text = accuracy;
            
            % Displaying suggestions
            randomSongs = ""; % Will be used to display other songs
            for i=1:3 % There will be 3 other songs
                randomSong = randsample(suggestions, 1); % randomly selects
                x = suggestions==randomSong; % gives the index of the selected song
                suggestions(x) = []; % pops the selected song from its array

                randomSong = strcat(string(i), ". ", randomSong); % adds index at the beginning
                randomSongs = strcat(randomSongs, randomSong, "\n"); % Combining all with newline character
            end
            randomSongs = compose(randomSongs); % Necessary for \n to work
            app.OtherSongs.Text = randomSongs; % Display
            
            % Letting the user know that the program is finished
            app.StartButton.Text = "Done!";

            app.canStart = false; % to prevent spamming the start button

        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
            % The play button should be able to be pressed when the audio is
            % selected and is not playing
            if app.audioCanBePlayed && ~app.isPlaying

                % Setting the player global variable to play/stop the audio
                [y, Fs] = audioread(app.fullPath);
                app.player = audioplayer(y, Fs);
                ResetPlayerButtons(app, false)

                play(app.player);

                app.isPaused = true;
                app.isPlaying = true;
                
                ResetPlayerButtons(app, true)
            end

        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            % The stop button should be able to be pressed when the audio is
            % selected and is playing
            if app.audioCanBePlayed && app.isPlaying
                stop(app.player);
                
                app.isPaused = true;
                app.isPlaying = false;
                
                ResetPlayerButtons(app, false)
            end
        end

        % Button pushed function: PauseButton
        function PauseButtonPushed(app, event)
            % Using same button for pause and resume
            % when playing it should pause
            % when not playing it should resume
            if app.audioCanBePlayed
                if app.isPaused
                    pause(app.player);
                    app.PauseButton.Text = "Resume";
                else
                    resume(app.player);
                    app.PauseButton.Text = "Pause";
                end
                app.isPaused = ~app.isPaused; % to alternate the values false and true
            end
        end

        % Value changed function: MachineLearningMethodDropDown
        function MachineLearningMethodDropDownValueChanged(app, event)
            % To use other models with the same audio file without having
            % to select the same audio file again
            if app.audioCanBePlayed
                app.canStart = true;
                app.StartButton.Text = "Start";

                ResetDisplay(app) % reset older genre, suggestion and accuracy
            end
        end

        % Close request function: ChazamUIFigure
        function ChazamUIFigureCloseRequest(app, event)
            if app.audioCanBePlayed && app.isPlaying % to stop audio if playing
                stop(app.player);
            end
            
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create ChazamUIFigure and hide until all components are created
            app.ChazamUIFigure = uifigure('Visible', 'off');
            app.ChazamUIFigure.Color = [0.8 0.8 0.8];
            colormap(app.ChazamUIFigure, 'cool');
            app.ChazamUIFigure.Position = [100.2 100.2 877 551];
            app.ChazamUIFigure.Name = 'Chazam';
            app.ChazamUIFigure.Icon = fullfile(pathToMLAPP, 'Sprites', 'icon.png');
            app.ChazamUIFigure.Resize = 'off';
            app.ChazamUIFigure.CloseRequestFcn = createCallbackFcn(app, @ChazamUIFigureCloseRequest, true);

            % Create Image
            app.Image = uiimage(app.ChazamUIFigure);
            app.Image.ScaleMethod = 'fill';
            app.Image.BackgroundColor = [1 0.4118 0.1608];
            app.Image.Position = [1 1 877 551];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'Sprites', 'background.jpg');

            % Create Label_2
            app.Label_2 = uilabel(app.ChazamUIFigure);
            app.Label_2.BackgroundColor = [0.9686 0.451 0];
            app.Label_2.Position = [185 229 278 40];
            app.Label_2.Text = '';

            % Create Label
            app.Label = uilabel(app.ChazamUIFigure);
            app.Label.BackgroundColor = [1 0.6 0.2588];
            app.Label.Position = [193 238 262 22];
            app.Label.Text = '';

            % Create StartButton
            app.StartButton = uibutton(app.ChazamUIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Icon = fullfile(pathToMLAPP, 'Sprites', 'button.png');
            app.StartButton.IconAlignment = 'center';
            app.StartButton.BackgroundColor = [0.9686 0.451 0];
            app.StartButton.FontSize = 36;
            app.StartButton.FontWeight = 'bold';
            app.StartButton.FontAngle = 'italic';
            app.StartButton.FontColor = [1 1 1];
            app.StartButton.Visible = 'off';
            app.StartButton.Position = [619 164 184 174];
            app.StartButton.Text = 'Start';

            % Create GenreBorder
            app.GenreBorder = uilabel(app.ChazamUIFigure);
            app.GenreBorder.BackgroundColor = [0.9686 0.451 0];
            app.GenreBorder.HorizontalAlignment = 'center';
            app.GenreBorder.FontSize = 18;
            app.GenreBorder.FontWeight = 'bold';
            app.GenreBorder.FontColor = [1 1 1];
            app.GenreBorder.Position = [619 435 184 66];
            app.GenreBorder.Text = '';

            % Create Genre
            app.Genre = uilabel(app.ChazamUIFigure);
            app.Genre.BackgroundColor = [1 0.6 0.2588];
            app.Genre.HorizontalAlignment = 'center';
            app.Genre.FontSize = 18;
            app.Genre.FontWeight = 'bold';
            app.Genre.FontColor = [1 1 1];
            app.Genre.Position = [627 443 169 50];
            app.Genre.Text = 'Genre';

            % Create OtherSongsBorder
            app.OtherSongsBorder = uilabel(app.ChazamUIFigure);
            app.OtherSongsBorder.BackgroundColor = [0.9686 0.451 0];
            app.OtherSongsBorder.HorizontalAlignment = 'center';
            app.OtherSongsBorder.WordWrap = 'on';
            app.OtherSongsBorder.FontSize = 24;
            app.OtherSongsBorder.FontWeight = 'bold';
            app.OtherSongsBorder.FontColor = [1 1 1];
            app.OtherSongsBorder.Position = [72 276 474 224];
            app.OtherSongsBorder.Text = 'Machine earning method:';

            % Create OtherSongs
            app.OtherSongs = uilabel(app.ChazamUIFigure);
            app.OtherSongs.BackgroundColor = [1 0.6 0.2588];
            app.OtherSongs.HorizontalAlignment = 'center';
            app.OtherSongs.WordWrap = 'on';
            app.OtherSongs.FontSize = 24;
            app.OtherSongs.FontWeight = 'bold';
            app.OtherSongs.FontColor = [1 1 1];
            app.OtherSongs.Position = [85 288 450 201];
            app.OtherSongs.Text = 'Our Suggestions';

            % Create PresstoSelectaFileButton
            app.PresstoSelectaFileButton = uibutton(app.ChazamUIFigure, 'push');
            app.PresstoSelectaFileButton.ButtonPushedFcn = createCallbackFcn(app, @PresstoSelectaFileButtonPushed, true);
            app.PresstoSelectaFileButton.Icon = fullfile(pathToMLAPP, 'Sprites', 'button2.png');
            app.PresstoSelectaFileButton.IconAlignment = 'center';
            app.PresstoSelectaFileButton.BackgroundColor = [0.9686 0.451 0];
            app.PresstoSelectaFileButton.FontSize = 18;
            app.PresstoSelectaFileButton.FontWeight = 'bold';
            app.PresstoSelectaFileButton.FontAngle = 'italic';
            app.PresstoSelectaFileButton.FontColor = [1 1 1];
            app.PresstoSelectaFileButton.Position = [205 112 238 97];
            app.PresstoSelectaFileButton.Text = 'Press to Select a File';

            % Create PlayButton
            app.PlayButton = uibutton(app.ChazamUIFigure, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.PlayButton.Position = [205 76 75 23];
            app.PlayButton.Text = 'Play';

            % Create StopButton
            app.StopButton = uibutton(app.ChazamUIFigure, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Enable = 'off';
            app.StopButton.Position = [368 76 75 23];
            app.StopButton.Text = 'Stop';

            % Create PauseButton
            app.PauseButton = uibutton(app.ChazamUIFigure, 'push');
            app.PauseButton.ButtonPushedFcn = createCallbackFcn(app, @PauseButtonPushed, true);
            app.PauseButton.Enable = 'off';
            app.PauseButton.Position = [287 76 75 23];
            app.PauseButton.Text = 'Pause';

            % Create MachineLearningMethodDropDownLabel
            app.MachineLearningMethodDropDownLabel = uilabel(app.ChazamUIFigure);
            app.MachineLearningMethodDropDownLabel.HorizontalAlignment = 'right';
            app.MachineLearningMethodDropDownLabel.FontColor = [1 1 1];
            app.MachineLearningMethodDropDownLabel.Position = [193 238 147 22];
            app.MachineLearningMethodDropDownLabel.Text = 'Machine Learning Method:';

            % Create MachineLearningMethodDropDown
            app.MachineLearningMethodDropDown = uidropdown(app.ChazamUIFigure);
            app.MachineLearningMethodDropDown.Items = {'Fine Tree', 'Medium Tree', 'Coarse Tree', 'Linear SVM', 'Quadratic SVM (Best Accuracy)', 'Fine KNN', 'Medium KNN', 'Coarse KNN', 'Boosted Trees', 'Narrow Neural Network', 'Medium Neural Network'};
            app.MachineLearningMethodDropDown.ValueChangedFcn = createCallbackFcn(app, @MachineLearningMethodDropDownValueChanged, true);
            app.MachineLearningMethodDropDown.BackgroundColor = [1 1 1];
            app.MachineLearningMethodDropDown.Position = [355 238 100 22];
            app.MachineLearningMethodDropDown.Value = 'Quadratic SVM (Best Accuracy)';

            % Create AccuracyBorder
            app.AccuracyBorder = uilabel(app.ChazamUIFigure);
            app.AccuracyBorder.BackgroundColor = [0.9686 0.451 0];
            app.AccuracyBorder.HorizontalAlignment = 'center';
            app.AccuracyBorder.FontSize = 18;
            app.AccuracyBorder.FontWeight = 'bold';
            app.AccuracyBorder.FontColor = [1 1 1];
            app.AccuracyBorder.Position = [619 355 184 66];
            app.AccuracyBorder.Text = '';

            % Create Accuracy
            app.Accuracy = uilabel(app.ChazamUIFigure);
            app.Accuracy.BackgroundColor = [1 0.6 0.2588];
            app.Accuracy.HorizontalAlignment = 'center';
            app.Accuracy.FontSize = 18;
            app.Accuracy.FontWeight = 'bold';
            app.Accuracy.FontColor = [1 1 1];
            app.Accuracy.Position = [627 363 169 50];
            app.Accuracy.Text = 'Accuracy';

            % Show the figure after all components are created
            app.ChazamUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Chazam_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.ChazamUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ChazamUIFigure)
        end
    end
end