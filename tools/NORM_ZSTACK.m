function Z=NORM_ZSTACK(Mz_stack,M0_stack,P,Segment,type)


if nargin<5
    type='M0';
end;

sizeMz=size(Mz_stack);
% ***KEY CHANGE 1:  Create Segment_4D to match Mz_stack dimensions***
Segment_4D = ones(sizeMz);

if ismatrix(Segment)
    for ii=1:sizeMz(3)
        Segment_4D(:,:,ii,:)= repmat(Segment, [1 1 1 sizeMz(4)]);
    end;
elseif ndims(Segment) == 3
    for ii = 1:sizeMz(4) % loop through offsets
        Segment_4D(:,:,:,ii) = Segment; % Replicate for slices
    end
else
    Segment_4D = Segment; % Already 4D, no replication needed
end;

ind_zeros=find(M0_stack==0);
M0_stack(ind_zeros)=0.001;


M0_stack_4D=ones(sizeMz);

switch type
    case 'M0'
        
        for ii=1:numel(P.SEQ.w)
            if (ndims(M0_stack)<4)
                M0_stack_4D(:,:,:,ii)=M0_stack;
            else
                M0_stack_4D(:,:,:,ii)=M0_stack(:,:,:,ii);
            end
            % ***KEY CHANGE 2: Use Segment_4D inside the loop with proper indexing***
            Mz_stack(:,:,:,ii) = Mz_stack(:,:,:,ii) .* Segment_4D(:,:,:,ii); 
        end;
        
    case 'baseline'

        for ii=1:sizeMz(1)
            for jj=1:sizeMz(2)
                if Segment_4D(ii,jj,1,1) == 1 % Only segment if first offset in Segment_4D is true.
                    M0_stack_4D(ii,jj,1,:)=interp1q([P.SEQ.w(1); P.SEQ.w(end)],[mean(Mz_stack(ii,jj,1,1:2),4) ; mean(Mz_stack(ii,jj,1,end-1:end),4)],P.SEQ.w);
                end
            end
        end
end;
        
        Z=Mz_stack./M0_stack_4D;