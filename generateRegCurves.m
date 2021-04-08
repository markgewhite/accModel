% ************************************************************************
% Function: generateRegCurves
% Purpose:  Generate registered curves in advance of modelling
%
%
% Parameters:
%       data
%       options
%
% Output:
%       saved file
%
% ************************************************************************

function generateRegCurves( data, opt )

if opt.reg.doInitialise
    
    % initialise
    for i = opt.reg.calcCurves
        for j = opt.reg.calcSensors
            for k = opt.reg.calcLM
                fdXReg.(opt.curveNames{i}) ...
                        .(opt.sensorNames{j}) ...
                        .(opt.lm.sets{k}) = ...
                                cell( opt.reg.nLambda, opt.reg.nWLambda );
                fdWReg.(opt.curveNames{i}) ...
                        .(opt.sensorNames{j}) ...
                        .(opt.lm.sets{k}) = ...
                                cell( opt.reg.nLambda, opt.reg.nWLambda );
                regopt.(opt.curveNames{i}) ...
                        .(opt.sensorNames{j}) ...
                        .(opt.lm.sets{k}) = ...
                                cell( opt.reg.nLambda, opt.reg.nWLambda );
            end
        end
    end

else
    
    load( opt.reg.filename );
    % add fields if required
    for i = opt.reg.calcCurves
        dataExists = isfield( fdXReg, opt.curveNames{i} );
        for j = opt.reg.calcSensors
            dataExists = dataExists && ...
                isfield(fdXReg.(opt.curveNames{i}), opt.sensorNames{j});
            for k = opt.reg.calcLM
                dataExists = dataExists && ...
                    isfield(fdXReg.(opt.curveNames{i}).(opt.sensorNames{j}), ...
                                                    opt.lm.sets{k} );
                if ~dataExists                          
                    fdXReg.(opt.curveNames{i}) ...
                            .(opt.sensorNames{j}) ...
                            .(opt.lm.sets{k}) = ...
                                    cell( opt.reg.nLambda, opt.reg.nWLambda );
                    fdWReg.(opt.curveNames{i}) ...
                            .(opt.sensorNames{j}) ...
                            .(opt.lm.sets{k}) = ...
                                    cell( opt.reg.nLambda, opt.reg.nWLambda );
                    regopt.(opt.curveNames{i}) ...
                            .(opt.sensorNames{j}) ...
                            .(opt.lm.sets{k}) = ...
                                    cell( opt.reg.nLambda, opt.reg.nWLambda );
                end
            end
        end
    end   

end


for i = opt.reg.calcCurves
    
    trnSelect = true( length(data.outcome), 1 );
    valSelect = false( length(data.outcome), 1 );
    
    for j = opt.reg.calcSensors
        
        for k = opt.reg.calcLM
            
            for l = opt.reg.calcLambda
                
                for m = opt.reg.calcWLambda
                    
                    opt.fda.lambda = 10^l;
                    opt.reg.wLambda = 10^m;
                    opt.lm.setApplied = opt.lm.sets{k};
                    opt.data.sensors = opt.data.sensorCodes{j};

                    disp(['Curve = ' char(opt.curveNames{i}) ...
                          '; Sensor =  ' char(opt.sensorNames{j}) ...
                          '; Landmark Set = ' char(opt.lm.sets{k}) ...
                          '; Amplitude Lambda = ' num2str(opt.fda.lambda) ...
                          '; Temporal Lambda = ' num2str(opt.reg.wLambda) ]);


                    tic;

                    % generate the registered curves (but won't run model)
                    [ ~, ~, regOutput ] = accModelRun(   ...
                                               data, ...
                                               'Specified', ...
                                               trnSelect, ...
                                               valSelect, ...
                                               opt, ...
                                               [] );

                    lIdx = opt.reg.lambdaIdxFcn( opt.fda.lambda );
                    mIdx = opt.reg.lambdaIdxFcn( opt.reg.wLambda );
                    fdXReg.(opt.curveNames{i}) ...
                                .(opt.sensorNames{j}) ...
                                .(opt.lm.sets{k}){lIdx,mIdx} = regOutput.fdXReg;
                    fdWReg.(opt.curveNames{i}) ...
                                .(opt.sensorNames{j}) ...
                                .(opt.lm.sets{k}){lIdx,mIdx} = regOutput.fdWReg;
                    regopt.(opt.curveNames{i}) ...
                                .(opt.sensorNames{j}) ...
                                .(opt.lm.sets{k}){lIdx,mIdx} = opt;
       
                    save( opt.reg.filename, ...
                            'fdXReg', 'fdWReg', 'regopt' );
                    disp('Saved file');
                            
                    computeTime = toc;
                    disp(['Computation Time = ' num2str(computeTime)]);
                    
                end
                
            end

        end

    end

end

    
end


    
    