% Generates and parse condition sets
%
% Author: Jonathan Karr, jkarr@stanford.edu
% Affilitation: Covert Lab, Department of Bioengineering, Stanford University
% Last updated: 7/28/2011
classdef ConditionSet
    %generate condition set
    methods (Static = true)
        function generateSingleGeneDeletionConditionSet(sim, metadata, geneWholeCellModelIDs, replicates, fileName)
            import edu.stanford.covert.cell.sim.util.ConditionSet;
            
            g = sim.gene;
            
            if strcmp(geneWholeCellModelIDs, '-all')
                geneWholeCellModelIDs = g.wholeCellModelIDs;
            elseif ischar(geneWholeCellModelIDs)
                geneWholeCellModelIDs = {geneWholeCellModelIDs};
            end
            
            conditions = repmat(struct(...
                'shortDescription', [], ...
                'longDescription', [], ...
                'replicates', replicates, ...
                'perturbations', struct(...
                    'geneticKnockouts', [])), ...
                numel(geneWholeCellModelIDs), 1);
            
            for i = 1:numel(geneWholeCellModelIDs)
                conditions(i).shortDescription = sprintf('Single-gene (%s; %s) deletion simulation set', ...
                    geneWholeCellModelIDs{i}, g.names{strcmp(g.wholeCellModelIDs, geneWholeCellModelIDs{i})});
                conditions(i).longDescription = sprintf('Single-gene (%s; %s) deletion simulation set with %d replicates', ...
                    geneWholeCellModelIDs{i}, g.names{strcmp(g.wholeCellModelIDs, geneWholeCellModelIDs{i})}, replicates);
                conditions(i).perturbations.geneticKnockouts = geneWholeCellModelIDs(i);
            end
            
            ConditionSet.generateConditionSet(sim, metadata, conditions, fileName);
        end
        
        function generateConditionSet(sim, metadata, conditions, fileName)
            import edu.stanford.covert.cell.sim.constant.Condition;
            comp = sim.compartment;
            stim = sim.state('Stimulus');
            m = sim.state('Metabolite');
            
            %initialize xml file
            fid = fopen(fileName, 'w');
            fprintf(fid, '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n');
            fprintf(fid, '<!-- Autogenerated by %s at %s -->\n',  'edu.stanford.covert.cell.sim.util.ConditionSet', datestr(now, 31));
            fprintf(fid, '<conditions\n');
            fprintf(fid, '    xmlns="http://covertlab.stanford.edu"\n');
            fprintf(fid, '    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n');
            fprintf(fid, '    xsi:schemaLocation="http://covertlab.stanford.edu runSimulations.xsd">\n');
            
            %metadata
            fprintf(fid, '    <firstName><![CDATA[%s]]></firstName>\n', metadata.firstName);
            fprintf(fid, '    <lastName><![CDATA[%s]]></lastName>\n', metadata.lastName);
            fprintf(fid, '    <email><![CDATA[%s]]></email>\n', metadata.email);
            fprintf(fid, '    <affiliation><![CDATA[%s]]></affiliation>\n', metadata.affiliation);
            fprintf(fid, '    <userName><![CDATA[%s]]></userName>\n', metadata.userName);
            fprintf(fid, '    <hostName><![CDATA[%s]]></hostName>\n', metadata.hostName);
            fprintf(fid, '    <ipAddress><![CDATA[%s]]></ipAddress>\n', metadata.ipAddress);
            fprintf(fid, '    <revision>%d</revision>\n', metadata.revision);
            fprintf(fid, '    <differencesFromRevision><![CDATA[%s]]></differencesFromRevision>\n', metadata.differencesFromRevision);
            
            %conditions
            for i = 1:numel(conditions)
                %open condition
                fprintf(fid, '    <condition>\n');
                
                %metadata
                fprintf(fid, '        <shortDescription><![CDATA[%s]]></shortDescription>\n', conditions(i).shortDescription);
                fprintf(fid, '        <longDescription><![CDATA[%s]]></longDescription>\n', conditions(i).longDescription);
                fprintf(fid, '        <replicates>%d</replicates>\n', conditions(i).replicates);
                
                %options
                if isfield(conditions(i), 'options') && isstruct(conditions(i).options)
                    %open
                    fprintf(fid, '        <options>\n');
                    
                    %global
                    fields = setdiff(fieldnames(conditions(i).options), {'states', 'processes'});
                    for j = 1:numel(fields)
                        fprintf(fid, '            <option name="%s" value="%s"/>\n', ...
                            fields{j}, edu.stanford.covert.io.jsonFormat(conditions(i).options(fields{j})));
                    end
                    
                    %states
                    if isfield(conditions(i).options, 'states')
                        fields = fieldnames(conditions(i).options.states);
                        for j = 1:numel(fields)
                            subfields = fieldnames(conditions(i).options.states.(fields{j}));
                            for k = 1:numel(subfields)
                                fprintf(fid, '            <option state="%s" name="%s" value="%s"/>\n', ...
                                    fields{j}, subfields{k}, ...
                                    edu.stanford.covert.io.jsonFormat(conditions(i).options.states.(fields{j}).(subfields{k})));
                            end
                        end
                    end
                    
                    %processes
                    if isfield(conditions(i).options, 'processes')
                        fields = fieldnames(conditions(i).options.processes);
                        for j = 1:numel(fields)
                            subfields = fieldnames(conditions(i).options.processes.(fields{j}));
                            for k = 1:numel(subfields)
                                fprintf(fid, '            <option process="%s" name="%s" value="%s"/>\n', ...
                                    fields{j}, subfields{k}, ...
                                    edu.stanford.covert.io.jsonFormat(conditions(i).options.processes.(fields{j}).(subfields{k})));
                            end
                        end
                    end
                    
                    %close
                    fprintf(fid, '        </options>\n');
                end
                
                %parameters
                if isfield(conditions(i), 'parameters') && isstruct(conditions(i).parameters)
                    %open
                    fprintf(fid, '        <parameters>\n');
                    
                    %states
                    if isfield(conditions(i).parameters, 'states')
                        fields = fieldnames(conditions(i).parameters.states);
                        for j = 1:numel(fields)
                            subfields = fieldnames(conditions(i).parameters.states.(fields{j}));
                            for k = 1:numel(subfields)
                                if isscalar(conditions(i).parameters.states.(fields{j}).(subfields{k}))
                                    fprintf(fid, '            <parameter state="%s" name="%s" value="%s"/>\n', ...
                                        fields{j}, subfields{k}, ...
                                        edu.stanford.covert.io.jsonFormat(conditions(i).parameters.states.(fields{j}).(subfields{k})));
                                else
                                    for l = 1:numel(conditions(i).parameters.states.(fields{j}).(subfields{k}))
                                        index = '';
                                        fprintf(fid, '            <parameter state="%s" name="%s" index="%s" value="%s"/>\n', ...
                                            fields{j}, subfields{k}, index, ...
                                            edu.stanford.covert.io.jsonFormat(conditions(i).parameters.states.(fields{j}).(subfields{k})));
                                    end
                                end
                            end
                        end
                    end
                    
                    %processes
                    if isfield(conditions(i).parameters, 'processes')
                        fields = fieldnames(conditions(i).parameters.processes);
                        for j = 1:numel(fields)
                            subfields = fieldnames(conditions(i).parameters.processes.(fields{j}));
                            for k = 1:numel(subfields)
                                if isscalar(conditions(i).parameters.processes.(fields{j}).(subfields{k}))
                                    fprintf(fid, '            <parameter process="%s" name="%s" value="%s"/>\n', ...
                                        fields{j}, subfields{k}, ...
                                        edu.stanford.covert.io.jsonFormat(conditions(i).parameters.processes.(fields{j}).(subfields{k})));
                                else
                                    for l = 1:numel(conditions(i).parameters.processes.(fields{j}).(subfields{k}))
                                        index='';
                                        fprintf(fid, '            <parameter process="%s" name="%s" index="%s" value="%s"/>\n', ...
                                            fields{j}, subfields{k}, index, ...
                                            edu.stanford.covert.io.jsonFormat(conditions(i).parameters.processes.(fields{j}).(subfields{k})));
                                    end
                                end
                            end
                        end
                    end
                    
                    %close
                    fprintf(fid, '        </parameters>\n');
                end
                
                %perturbations
                if isfield(conditions(i), 'perturbations') && isstruct(conditions(i).perturbations)
                    %close
                    fprintf(fid, '        <perturbations>\n');
                    
                    %genetic knockouts
                    if isfield(conditions(i).perturbations, 'geneticKnockouts')
                        for j = 1:size(conditions(i).perturbations.geneticKnockouts, 1)
                            fprintf(fid, '            <perturbation type="%s" component="%s"/>\n', ...
                                'geneticKnockout', conditions(i).perturbations.geneticKnockouts{j});
                        end
                    end
                    
                    %stimulus
                    if isfield(conditions(i).perturbations, 'stimulus')
                        for j = 1:size(conditions(i).perturbations.stimulus, 1)
                            fprintf(fid, '            <perturbation type="%s" component="%s" compartment="%s" initialTime="%f" finalTime="%f" value="%f"/>\n', ...
                                'stimulus', ....
                                stim.wholeCellModelIDs{conditions(i).perturbations.stimulus(j, Condition.objectIndexs)}, ...
                                comp.wholeCellModelIDs{conditions(i).perturbations.stimulus(j, Condition.compartmentIndexs)}, ...
                                conditions(i).perturbations.stimulus(j, Condition.initialTimeIndexs), ...
                                conditions(i).perturbations.stimulus(j, Condition.finalTimeIndexs), ...
                                conditions(i).perturbations.stimulus(j, Condition.valueIndexs));
                        end
                    end
                    
                    %media
                    if isfield(conditions(i).perturbations, 'media')
                        for j = 1:size(conditions(i).perturbations.media, 1)
                            fprintf(fid, '            <perturbation type="%s" component="%s" compartment="%s" initialTime="%f" finalTime="%f" value="%f"/>\n', ...
                                'media', ....
                                m.wholeCellModelIDs{conditions(i).perturbations.media(j, Condition.objectIndexs)}, ...
                                comp.wholeCellModelIDs{conditions(i).perturbations.media(j, Condition.compartmentIndexs)}, ...
                                conditions(i).perturbations.media(j, Condition.initialTimeIndexs), ...
                                conditions(i).perturbations.media(j, Condition.finalTimeIndexs), ...
                                conditions(i).perturbations.media(j, Condition.valueIndexs));
                        end
                    end
                    
                    %close
                    fprintf(fid, '        </perturbations>\n');
                end
                
                %close condition
                fprintf(fid, '    </condition>\n');
            end
            
            %finalize xml file
            fprintf(fid, '</conditions>\n');
            fclose(fid);
        end
    end
    
    %parse condition set
    methods (Static)
        function data = parseConditionSet(sim, fileName)
            import edu.stanford.covert.cell.sim.constant.Condition;
            
            data = struct(...
                'metadata', struct(...
                    'firstName', [], ...
                    'lastName', [], ...
                    'email', [], ...
                    'affiliation', [], ...
                    'userName', [], ...
                    'hostName', []', ...
                    'ipAddress', [], ...
                    'revision', [], ...
                    'differencesFromRevision', [], ...
                    'shortDescription', [], ...
                    'longDescription', []), ...
                'options', struct('states',struct,'processes',struct), ...
                'parameters', struct('states',struct,'processes',struct), ...
                'perturbations', struct('geneticKnockouts', [], 'stimulus', [], 'media', []));
            data.perturbations.geneticKnockouts = cell(0, 1);
            data.perturbations.stimulus = zeros(0, 6);
            data.perturbations.media = zeros(0, 6);
            
            xml = xmlread(fileName);
            edu.stanford.covert.cell.sim.util.ConditionSet.validateConditionSet(xml);
            
            condition = xml.getElementsByTagName('condition').item(0);
            
            %metadata
            data.metadata.firstName = char(xml.getElementsByTagName('firstName').item(0).getFirstChild.getNodeValue);
            data.metadata.lastName = char(xml.getElementsByTagName('lastName').item(0).getFirstChild.getNodeValue);
            data.metadata.email = char(xml.getElementsByTagName('email').item(0).getFirstChild.getNodeValue);
            data.metadata.affiliation = char(xml.getElementsByTagName('affiliation').item(0).getFirstChild.getNodeValue);
            data.metadata.userName = char(xml.getElementsByTagName('userName').item(0).getFirstChild.getNodeValue);
            data.metadata.hostName = char(xml.getElementsByTagName('hostName').item(0).getFirstChild.getNodeValue);
            data.metadata.ipAddress = char(xml.getElementsByTagName('ipAddress').item(0).getFirstChild.getNodeValue);
            data.metadata.revision = str2double(char(xml.getElementsByTagName('revision').item(0).getFirstChild.getNodeValue));
            tmp = xml.getElementsByTagName('differencesFromRevision');
            if tmp.getLength() > 0 && tmp.item(0).getChildNodes.getLength() > 0
                data.metadata.differencesFromRevision = char(tmp.item(0).getFirstChild.getNodeValue);
            else
                data.metadata.differencesFromRevision = char([]);
            end
            data.metadata.shortDescription = char(condition.getElementsByTagName('shortDescription').item(0).getFirstChild.getNodeValue);
            data.metadata.longDescription = char(condition.getElementsByTagName('longDescription').item(0).getFirstChild.getNodeValue);
            
            %options
            options = xml.getElementsByTagName('option');
            for i = 1:options.getLength
                option = options.item(i-1);
                
                name = char(option.getAttribute('name'));
                state = char(option.getAttribute('state'));
                process = char(option.getAttribute('process'));
                value = char(option.getAttribute('value'));
                [tmp, status] = str2num(value); %#ok<*ST2NM>
                if status
                    value = tmp;
                end
                
                if ~isempty(state)
                    data.options.states.(state).(name) = value;
                elseif ~isempty(process)
                    data.options.processes.(process).(name) = value;
                else
                    data.options.(name) = value;
                end
            end
            
            %parameters
            parameters = xml.getElementsByTagName('parameter');
            for i=1:parameters.getLength
                parameter = parameters.item(i-1);
                
                name = char(parameter.getAttribute('name'));
                indexName = char(parameter.getAttribute('index'));
                state = strrep(char(parameter.getAttribute('state')), 'State_', '');
                process = strrep(char(parameter.getAttribute('process')), 'Process_', '');
                value = char(parameter.getAttribute('value'));
                [tmp, status] = str2num(value);
                if status
                    value = tmp;
                end
                
                if ~isempty(state)
                    if isempty(indexName)
                        data.parameters.states.(state).(name) = value;
                    else
                        index = sim.state(state).(indexName);
                        data.parameters.states.(state).(name)(index) = value;
                    end
                elseif ~isempty(process)
                    if isempty(indexName)
                        data.parameters.processes.(process).(name) = value;
                    else
                        index = sim.process(process).(indexName);
                        data.parameters.processes.(process).(name)(index) = value;
                    end
                else
                    if isempty(indexName)
                        data.parameters.(name) = value;
                    else
                        index = sim.(indexName);
                        data.parameters.(name)(index) = value;
                    end
                end
            end
            
            %perturbations
            s = sim.state('Stimulus');
            m = sim.state('Metabolite');
            nStim = numel(s.wholeCellModelIDs);
            nMet = numel(m.wholeCellModelIDs);
            nComp = sim.compartment.count;
            
            perturbations = xml.getElementsByTagName('perturbation');
            for i=1:perturbations.getLength
                perturbation = perturbations.item(i-1);
                
                type = char(perturbation.getAttribute('type'));
                componentName = char(perturbation.getAttribute('component'));
                compartmentName = char(perturbation.getAttribute('compartment'));
                initialTime = char(perturbation.getAttribute('initialTime'));
                initialTime = strrep(initialTime, 'INF','Inf');
                initialTime = str2double(initialTime);
                finalTime = char(perturbation.getAttribute('finalTime'));
                finalTime = strrep(finalTime, 'INF','Inf');
                finalTime = str2double(finalTime);                
                value = char(perturbation.getAttribute('value'));
                value = strrep(value, 'INF','Inf');
                value = str2double(value);
                
                switch (type)
                    case 'geneticKnockout'
                        data.perturbations.geneticKnockouts = [
                            data.perturbations.geneticKnockouts;
                            {componentName}];
                    case 'stimulus'
                        component = s.getIndexs(componentName);
                        compartment = sim.compartment.getIndexs(compartmentName);
                        data.perturbations.stimulus = [
                            data.perturbations.stimulus;
                            component compartment value initialTime finalTime sub2ind([nStim nComp], component, compartment)];
                    case 'media'
                        component = m.getIndexs(componentName);
                        compartment = sim.compartment.getIndexs(compartmentName);
                        data.perturbations.media = [
                            data.perturbations.media;
                            component compartment value initialTime finalTime sub2ind([nMet nComp], component, compartment)];
                end
            end           
        end
        
        function validateConditionSet(xml)
            hasConditions = 0;
            for i = 1:xml.getChildNodes.getLength
                child = xml.getChildNodes.item(i-1);
                switch char(child.getNodeName)
                    case {'#comment', '#text'}
                    case 'conditions'
                        hasConditions = hasConditions+1;
                        edu.stanford.covert.cell.sim.util.ConditionSet.validateConditions(child);
                    otherwise
                        throw(MException('ConditionSet:invalidXML','invalid XML'));
                end
            end
            if hasConditions~=1
                throw(MException('ConditionSet:invalidXML','invalid XML'));
            end
        end
        
        function validateConditions(xml)
            hasFirstName = 0;
            hasLastName = 0;
            hasEmail = 0;
            hasAffiliation = 0;
            hasUserName = 0;
            hasHostName = 0;
            hasIpAddress = 0;
            hasRevision = 0;
            hasDifferencesFromRevision = 0;
            hasCondition = 0;
            for i = 1:xml.getChildNodes.getLength
                child = xml.getChildNodes.item(i-1);
                switch char(child.getNodeName)
                    case {'#comment', '#text'}
                    case 'firstName'
                        hasFirstName = hasFirstName+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'lastName'
                        hasLastName = hasLastName+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'email'
                        hasEmail = hasEmail+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'affiliation'
                        hasAffiliation = hasAffiliation+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'userName'
                        hasUserName = hasUserName+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'hostName'
                        hasHostName = hasHostName+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'ipAddress'
                        hasIpAddress = hasIpAddress+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'revision'
                        hasRevision = hasRevision+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'differencesFromRevision'
                        hasDifferencesFromRevision = hasDifferencesFromRevision+1;
                    case 'condition'
                        hasCondition = hasCondition+1;
                        edu.stanford.covert.cell.sim.util.ConditionSet.validateCondition(child);
                    otherwise
                        throw(MException('ConditionSet:invalidXML','invalid XML'));
                end
            end
            if      hasFirstName~=1 || hasLastName~=1 || hasEmail~=1 || hasAffiliation~=1 || ...
                    hasUserName~=1 || hasHostName~=1 || hasIpAddress~=1 || hasRevision~=1 || hasDifferencesFromRevision~=1 || ...
                    hasCondition~=1
                throw(MException('ConditionSet:invalidXML','invalid XML'));
            end
        end
        
        function validateCondition(xml)
            hasName = 0;
            hasDescription = 0;
            for i = 1:xml.getChildNodes.getLength
                child = xml.getChildNodes.item(i-1);
                switch char(child.getNodeName)
                    case {'#comment', '#text'}
                    case 'shortDescription'
                        hasName = hasName+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'longDescription'
                        hasDescription = hasDescription+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'replicates'
                        [x, status] = str2num(char(child.getFirstChild.getNodeValue)); %#ok<ST2NM>
                        if ~status
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                        validateattributes(x, {'numeric'}, {'real', 'nonnegative', 'integer'});
                    case 'options'
                        edu.stanford.covert.cell.sim.util.ConditionSet.validateOptions(child);
                    case 'parameters'
                        edu.stanford.covert.cell.sim.util.ConditionSet.validateParameters(child);
                    case 'perturbations'
                        edu.stanford.covert.cell.sim.util.ConditionSet.validatePerturbations(child);
                    otherwise
                        throw(MException('ConditionSet:invalidXML','invalid XML'));
                end
            end
            if hasName~=1 || hasDescription~=1
                throw(MException('ConditionSet:invalidXML','invalid XML'));
            end
        end
        
        function validateOptions(xml)
            for i = 1:xml.getChildNodes.getLength
                child = xml.getChildNodes.item(i-1);
                switch char(child.getNodeName)
                    case {'#comment', '#text'}
                    case 'option'
                        edu.stanford.covert.cell.sim.util.ConditionSet.validateOption(child);
                    otherwise
                        throw(MException('ConditionSet:invalidXML','invalid XML'));
                end
            end
        end
        
        function validateOption(xml)
            hasName = 0;
            hasState = 0;
            hasProcess = 0;
            for i = 1:xml.getAttributes.getLength
                child = xml.getAttributes.item(i-1);
                switch char(child.getNodeName)
                    case {'#comment', '#text'}
                    case 'name'
                        hasName = hasName+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'state'
                        hasState = hasState+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'process'
                        hasProcess = hasProcess+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'value'
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    otherwise
                        throw(MException('ConditionSet:invalidXML','invalid XML'));
                end
            end
            if hasName~=1 || (hasState+hasProcess)>1
                throw(MException('ConditionSet:invalidXML','invalid XML'));
            end
        end
        
        function validateParameters(xml)
            for i = 1:xml.getChildNodes.getLength
                child = xml.getChildNodes.item(i-1);
                switch char(child.getNodeName)
                    case {'#comment', '#text'}
                    case 'parameter'
                        edu.stanford.covert.cell.sim.util.ConditionSet.validateParameter(child);
                    otherwise
                        throw(MException('ConditionSet:invalidXML','invalid XML'));
                end
            end
        end
        
        function validateParameter(xml)
            hasName = 0;
            hasState = 0;
            hasProcess = 0;
            for i = 1:xml.getAttributes.getLength
                child = xml.getAttributes.item(i-1);
                switch char(child.getNodeName)
                    case {'#comment', '#text'}
                    case 'name'
                        hasName = hasName+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'index'
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'state'
                        hasState = hasState+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'process'
                        hasProcess = hasProcess+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'value'
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    otherwise
                        throw(MException('ConditionSet:invalidXML','invalid XML'));
                end
            end
            if hasName~=1 || (hasState+hasProcess)~=1
                throw(MException('ConditionSet:invalidXML','invalid XML'));
            end
        end
        
        function validatePerturbations(xml)
            for i = 1:xml.getChildNodes.getLength
                child = xml.getChildNodes.item(i-1);
                switch char(child.getNodeName)
                    case {'#comment', '#text'}
                    case 'perturbation'
                        edu.stanford.covert.cell.sim.util.ConditionSet.validatePerturbation(child);
                    otherwise
                        throw(MException('ConditionSet:invalidXML','invalid XML'));
                end
            end
        end
        
        function validatePerturbation(xml)
            hasType = 0;
            hasComponent = 0;
            hasCompartment = 0;
            hasTime = 0;
            hasValue = 0;
            for i = 1:xml.getAttributes.getLength
                child = xml.getAttributes.item(i-1);
                switch char(child.getNodeName)
                    case {'#comment', '#text'}
                    case 'type'
                        type = char(child.getFirstChild.getNodeValue);
                        hasType = hasType+1;
                        if ~all(ismember(type, {'geneticKnockout', 'stimulus', 'media'}));
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'component'
                        hasComponent = hasComponent+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case 'compartment'
                        hasCompartment = hasCompartment+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    case {'initialTime', 'finalTime'}
                        hasTime = hasTime+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                        val = char(child.getFirstChild.getNodeValue);
                        val = strrep(val, 'INF','Inf');
                        [x, status] = str2num(val); %#ok<ST2NM>
                        if ~status
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                        validateattributes(x, {'numeric'}, {'real', 'nonnegative'});
                    case 'value'
                        hasValue = hasValue+1;
                        if isempty(char(child.getFirstChild.getNodeValue))
                            throw(MException('ConditionSet:invalidXML','invalid XML'));
                        end
                    otherwise
                        throw(MException('ConditionSet:invalidXML','invalid XML'));
                end
            end
            if hasType~=1 || hasComponent~=1 || (strcmp(type, 'geneticKnockout') && (hasCompartment || hasTime || hasValue)) || ...
                    (~strcmp(type, 'geneticKnockout') && (~hasCompartment || ~hasValue))
                throw(MException('ConditionSet:invalidXML','invalid XML'));
            end
        end
    end
end